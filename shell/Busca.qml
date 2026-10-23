import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "tema"

// Busca global (docs/design/telas/Busca.dc.html): apps instalados, arquivos da pasta pessoal e ações
// sobre o primeiro arquivo. Abre pela dock ou por Super + Espaço, numa camada acima de tudo.
PanelWindow {
    id: busca

    // var (e não Pastas) para não criar dependência entre os tipos.
    property var pastas
    property bool aberta: false
    property string consulta: ""
    property var apps: []
    property var arquivos: []
    // Lista plana para a tela: cabeçalhos de grupo ({ cabecalho }) e resultados.
    property var linhas: []
    property int atual: -1

    readonly property var localidade: Qt.locale("pt_BR")
    readonly property string inicio: Quickshell.env("HOME")

    function abrir() {
        consulta = ""
        campo.text = ""
        aberta = true
        campo.forceActiveFocus()
    }
    function fechar() { aberta = false }
    function alternar() { aberta ? fechar() : abrir() }

    // Sem acentos e em minúsculas, para "musica" achar "Música".
    function normalizar(texto) {
        return (texto ?? "").normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase()
    }

    function buscarApps() {
        const q = normalizar(consulta.trim())
        if (q === "") { apps = []; return }
        const achados = []
        for (const e of DesktopEntries.applications.values) {
            if (e.noDisplay) continue
            const nome = normalizar(e.name)
            const extra = normalizar([e.genericName, e.comment].concat(e.keywords).join(" "))
            if (!nome.includes(q) && !extra.includes(q)) continue
            achados.push({ entrada: e, peso: nome.startsWith(q) ? 0 : nome.includes(q) ? 1 : 2 })
        }
        achados.sort((a, b) => a.peso - b.peso || a.entrada.name.localeCompare(b.entrada.name))
        apps = achados.slice(0, 5).map(a => ({
            tipo: "app", entrada: a.entrada, nome: a.entrada.name, iconeApp: a.entrada.icon,
            meta: a.entrada.genericName || a.entrada.comment || qsTr("Aplicativo"), cor: Tema.corApp
        }))
    }

    function lerArquivos(saida) {
        arquivos = saida.split("\n").filter(l => l !== "").map(l => {
            const [epoca, tipo, caminho] = l.split("\t")
            const pasta = tipo === "d"
            const dentro = caminho.substring(0, caminho.lastIndexOf("/"))
            const local = dentro === inicio ? qsTr("Início")
                        : dentro.startsWith(inicio + "/") ? dentro.substring(inicio.length + 1).split("/").join(" › ") : dentro
            const quando = new Date(parseFloat(epoca) * 1000).toLocaleString(localidade, "dd/MM/yyyy HH:mm")
            return {
                tipo: "arquivo", caminho: caminho, pasta: pasta, pastaPai: dentro,
                nome: caminho.substring(caminho.lastIndexOf("/") + 1),
                meta: qsTr("%1 · %2 · modificado %3").arg(pasta ? qsTr("Pasta") : qsTr("Arquivo")).arg(local).arg(quando),
                icone: pasta ? Icones.pasta : Icones.documento, cor: Tema.principal
            }
        })
    }

    function montar() {
        const acoes = arquivos.length > 0 ? [{
            tipo: "acao", nome: qsTr("Mostrar “%1” na pasta").arg(arquivos[0].nome),
            meta: qsTr("Abrir %1 no navegador de pastas").arg(arquivos[0].meta.split(" · ")[1]),
            icone: Icones.abrirPasta, cor: Tema.principalClaro, pastaPai: arquivos[0].pastaPai
        }] : []
        const grupos = [[qsTr("Arquivos"), arquivos], [qsTr("Apps"), apps], [qsTr("Ações"), acoes]]
        const saida = []
        for (const [titulo, itens] of grupos) {
            if (itens.length === 0) continue
            saida.push({ cabecalho: titulo })
            for (const item of itens) saida.push(item)
        }
        linhas = saida
        atual = saida.findIndex(l => !l.cabecalho)
    }

    function mover(passo) {
        let i = atual
        do { i += passo } while (i >= 0 && i < linhas.length && linhas[i].cabecalho)
        if (i >= 0 && i < linhas.length) {
            atual = i
            lista.positionViewAtIndex(i, ListView.Contain)
        }
    }

    function acionar(i) {
        const item = linhas[i]
        if (!item || item.cabecalho) return
        if (item.tipo === "app") item.entrada.execute()
        else if (item.tipo === "arquivo") {
            if (item.pasta) pastas.abrir(item.caminho)
            else Quickshell.execDetached(["xdg-open", item.caminho])
        } else if (item.tipo === "acao") pastas.abrir(item.pastaPai)
        fechar()
    }

    onConsultaChanged: {
        buscarApps()
        arquivos = []
        procura.running = false
        if (consulta.trim().length >= 2) espera.restart()
        montar()
    }
    onAppsChanged: montar()
    onArquivosChanged: montar()

    // Espera o usuário parar de digitar antes de vasculhar o disco.
    Timer {
        id: espera
        interval: 200
        onTriggered: {
            procura.padrao = busca.consulta.trim().replace(/[\\*?\[\]]/g, "\\$&")
            procura.running = true
        }
    }

    // Arquivos e pastas da pasta pessoal (sem os ocultos), os mais recentes primeiro.
    Process {
        id: procura
        property string padrao
        command: ["sh", "-c",
            "find \"$HOME\" -xdev -maxdepth 6 -name '.*' -prune -o -iname \"*$1*\" -printf '%T@\\t%y\\t%p\\n' 2>/dev/null"
            + " | sort -rn | head -n 6", "sh", padrao]
        stdout: StdioCollector {
            onStreamFinished: busca.lerArquivos(text)
        }
    }

    GlobalShortcut {
        appid: "terminus"
        name: "busca"
        description: qsTr("Abrir a busca global")
        onPressed: busca.alternar()
    }

    visible: aberta
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: Tema.veuBusca
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "terminus-busca"
    WlrLayershell.keyboardFocus: aberta ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    MouseArea {
        anchors.fill: parent
        onClicked: busca.fechar()
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        y: Tema.topoBusca * busca.height / 1080
        width: Math.min(Tema.larguraBusca, busca.width - 2 * Tema.margemTela)
        spacing: 20

        Esfera {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Tema.esferaBusca
            Layout.preferredHeight: Tema.esferaBusca
            estado: procura.running ? "pensando" : "repouso"
            animando: busca.aberta
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: colunaCaixa.implicitHeight
            radius: Tema.raioBusca
            color: Tema.vidroJanela
            border.color: Tema.bordaBusca
            clip: true
            Accessible.role: Accessible.Dialog
            Accessible.name: qsTr("Busca global")

            // Clique dentro da caixa não fecha a busca.
            MouseArea { anchors.fill: parent }

            ColumnLayout {
                id: colunaCaixa
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Tema.alturaCampoBusca
                    Layout.leftMargin: 24
                    Layout.rightMargin: 24
                    spacing: 16

                    Icone {
                        caminhos: Icones.busca
                        tamanho: 24
                        espessura: 2
                        cor: Tema.principal
                    }
                    TextField {
                        id: campo
                        Layout.fillWidth: true
                        Layout.preferredHeight: 56
                        placeholderText: qsTr("Buscar apps e arquivos")
                        placeholderTextColor: Tema.textoMarcador
                        color: Tema.textoTitulo
                        font.family: Tema.fonteTexto
                        font.pixelSize: Tema.tamanhoCampoBusca
                        background: null
                        Accessible.name: qsTr("Buscar apps e arquivos")
                        onTextChanged: busca.consulta = text
                        onAccepted: busca.acionar(busca.atual)
                        Keys.onEscapePressed: busca.fechar()
                        Keys.onUpPressed: busca.mover(-1)
                        Keys.onDownPressed: busca.mover(1)
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Tema.linhaDivisoria
                    visible: busca.linhas.length > 0 || busca.consulta.trim() !== ""
                }

                ListView {
                    id: lista
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(contentHeight + 24, Tema.alturaMaximaResultados)
                    Layout.leftMargin: 12
                    Layout.rightMargin: 12
                    visible: busca.linhas.length > 0
                    topMargin: 10
                    bottomMargin: 14
                    spacing: 2
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: busca.linhas
                    delegate: Item {
                        required property var modelData
                        required property int index
                        width: ListView.view.width
                        height: modelData.cabecalho ? cabecalho.implicitHeight : resultado.height

                        Text {
                            id: cabecalho
                            visible: modelData.cabecalho !== undefined
                            leftPadding: 14
                            topPadding: 10
                            bottomPadding: 6
                            text: modelData.cabecalho ?? ""
                            color: Tema.textoDiscreto
                            font.family: Tema.fonteTexto
                            font.weight: Font.DemiBold
                            font.pixelSize: Tema.tamanhoLegenda
                            font.letterSpacing: Tema.espacamentoRotulo
                            font.capitalization: Font.AllUppercase
                        }
                        // Só as linhas de resultado criam o componente; os cabeçalhos não têm esses dados.
                        Loader {
                            id: resultado
                            active: modelData.cabecalho === undefined
                            width: parent.width
                            sourceComponent: ResultadoBusca {
                                dados: modelData
                                selecionado: busca.atual === index
                                onApontado: busca.atual = index
                                onAcionado: busca.acionar(index)
                            }
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    Layout.margins: 24
                    visible: busca.linhas.length === 0 && busca.consulta.trim() !== "" && !procura.running && !espera.running
                    text: qsTr("Nada encontrado para “%1”.").arg(busca.consulta.trim())
                    color: Tema.textoDiscreto
                    font.family: Tema.fonteTexto
                    font.pixelSize: Tema.tamanhoTexto
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Tema.linhaDivisoria
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Tema.alturaRodapeBusca
                    Layout.leftMargin: 24
                    Layout.rightMargin: 24
                    spacing: 22

                    Repeater {
                        model: [["Enter", qsTr("abrir")], ["↑ ↓", qsTr("navegar")], ["Esc", qsTr("fechar")]]
                        delegate: Text {
                            required property var modelData
                            textFormat: Text.StyledText
                            text: "<font color='" + Tema.textoSecundario + "'><b>" + modelData[0] + "</b></font> " + modelData[1]
                            color: Tema.textoDiscreto
                            font.family: Tema.fonteTexto
                            font.pixelSize: Tema.tamanhoRotulo
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        textFormat: Text.StyledText
                        text: qsTr("Atalho: %1").arg("<font color='" + Tema.textoSecundario + "'><b>Super + Espaço</b></font>")
                        color: Tema.textoDiscreto
                        font.family: Tema.fonteTexto
                        font.pixelSize: Tema.tamanhoRotulo
                    }
                }
            }
        }
    }
}
