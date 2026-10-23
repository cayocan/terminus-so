import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "tema"

// Conversa digitada com o assistente, até a voz chegar: abre pelo clique na esfera ou por Super + A, no mesmo
// visual da busca global. No primeiro uso, oferece baixar o modelo e mostra o progresso.
PanelWindow {
    id: janela

    required property Assistente assistente
    property string nomeAssistente: "Terminus"
    property bool aberta: false
    // Verdadeiro enquanto há um pedido de confirmação na tela (ConfirmacaoAcao precisa do teclado).
    property bool cederTeclado: false

    readonly property var modelo: assistente.modelo
    readonly property bool pronto: modelo.estado === "pronto"
    readonly property bool esperando: assistente.perguntaPendente !== ""
    // Na tela principal a resposta some depois de um tempo; aqui fica até a próxima pergunta.
    property var ultima: null
    Connections {
        target: janela.assistente
        function onRespostaChanged() { if (janela.assistente.resposta) janela.ultima = janela.assistente.resposta }
        function onPerguntaPendenteChanged() { if (janela.esperando) janela.ultima = null }
    }

    function abrir() {
        aberta = true
        campo.forceActiveFocus()
    }
    function fechar() { aberta = false }
    function alternar() { aberta ? fechar() : abrir() }
    function enviar() {
        if (campo.text.trim() === "" || esperando) return
        assistente.perguntar(campo.text)
        campo.text = ""
    }
    function gigas(bytes) {
        return (bytes / 1e9).toLocaleString(Qt.locale("pt_BR"), "f", 1)
    }

    readonly property string rotuloFerramenta: ({
        sistema_info: qsTr("Olhando o sistema"), volume_ler: qsTr("Olhando o volume"),
        volume_definir: qsTr("Mudando o volume"), apps_listar: qsTr("Procurando o app"),
        app_abrir: qsTr("Abrindo o app"), janelas_listar: qsTr("Olhando as janelas"),
        janela_focar: qsTr("Trazendo a janela"), janela_fechar: qsTr("Fechando a janela"),
        arquivos_listar: qsTr("Olhando a pasta"), arquivo_ler: qsTr("Lendo o arquivo"),
        pasta_criar: qsTr("Criando a pasta"), arquivo_mover: qsTr("Movendo"), arquivo_lixeira: qsTr("Mandando para a Lixeira"),
        tela_abrir: qsTr("Abrindo a tela"), esfera_estado: qsTr("Mudando a esfera"), cores_definir: qsTr("Trocando as cores"),
        avisar: qsTr("Avisando"), areas_listar: qsTr("Olhando as áreas"), area_criar: qsTr("Criando a área"),
        area_minimizar: qsTr("Mexendo na área"), historico_listar: qsTr("Olhando o histórico")
    })[assistente.agindo] ?? (assistente.agindo !== "" ? qsTr("Usando %1").arg(assistente.agindo) : qsTr("Pensando"))

    GlobalShortcut {
        appid: "terminus"
        name: "assistente"
        description: qsTr("Conversar com o assistente")
        onPressed: janela.alternar()
    }

    visible: aberta
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: Tema.veuBusca
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "terminus-assistente"
    // Uma confirmação pedida pelo assistente aparece por cima; o teclado passa para ela enquanto isso.
    WlrLayershell.keyboardFocus: aberta && !cederTeclado ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    onCederTecladoChanged: if (!cederTeclado && aberta) campo.forceActiveFocus()

    MouseArea {
        anchors.fill: parent
        onClicked: janela.fechar()
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        y: Tema.topoBusca * janela.height / 1080
        width: Math.min(Tema.larguraBusca, janela.width - 2 * Tema.margemTela)
        spacing: 20

        Esfera {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Tema.esferaBusca
            Layout.preferredHeight: Tema.esferaBusca
            estado: janela.esperando ? "pensando" : janela.assistente.esfera
            animando: janela.aberta
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: colunaCaixa.implicitHeight
            radius: Tema.raioBusca
            color: Tema.vidroJanela
            border.color: Tema.bordaBusca
            clip: true
            Accessible.role: Accessible.Dialog
            Accessible.name: qsTr("Conversar com %1").arg(janela.nomeAssistente)

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
                        caminhos: Icones.esfera
                        tamanho: 24
                        espessura: 2
                        cor: Tema.principal
                    }
                    TextField {
                        id: campo
                        Layout.fillWidth: true
                        Layout.preferredHeight: 56
                        enabled: janela.pronto
                        placeholderText: janela.pronto ? qsTr("Pergunte ou peça algo a %1").arg(janela.nomeAssistente)
                                                       : qsTr("O assistente ainda não está pronto")
                        placeholderTextColor: Tema.textoMarcador
                        color: Tema.textoTitulo
                        font.family: Tema.fonteTexto
                        font.pixelSize: Tema.tamanhoCampoBusca
                        background: null
                        Accessible.name: qsTr("Pergunta para o assistente")
                        onAccepted: janela.enviar()
                        Keys.onEscapePressed: janela.fechar()
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Tema.linhaDivisoria
                    visible: conversa.visible || estadoModelo.visible
                }

                // Modelo ainda não está pronto: download no primeiro uso, carregando ou erro.
                ColumnLayout {
                    id: estadoModelo
                    Layout.fillWidth: true
                    Layout.margins: 24
                    spacing: 14
                    visible: !janela.pronto

                    Text {
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        color: Tema.texto
                        font.family: Tema.fonteTexto
                        font.pixelSize: Tema.tamanhoTextoGrande
                        text: {
                            const m = janela.modelo
                            if (m.estado === "ausente")
                                return qsTr("Para conversar, preciso baixar o modelo %1 (%2 GB). É só uma vez, e depois tudo roda neste computador, sem internet.")
                                    .arg(m.nome).arg(janela.gigas(m.tamanho))
                            if (m.estado === "baixando")
                                return qsTr("Baixando %1… %2% (%3 de %4 GB)").arg(m.nome).arg(Math.floor(m.progresso * 100))
                                    .arg(janela.gigas(m.progresso * m.tamanho)).arg(janela.gigas(m.tamanho))
                            if (m.estado === "erro") return qsTr("O modelo não subiu: %1").arg(m.erro)
                            if (!janela.assistente.conectado) return qsTr("O assistente não está rodando.")
                            return qsTr("Carregando o modelo %1…").arg(m.nome ?? "")
                        }
                    }
                    Text {
                        Layout.fillWidth: true
                        visible: janela.modelo.estado === "ausente"
                        wrapMode: Text.Wrap
                        text: (janela.modelo.descricao ?? "") + (janela.modelo.erro ? "  " + janela.modelo.erro : "")
                        color: janela.modelo.erro ? Tema.erroTexto : Tema.textoDiscreto
                        font.family: Tema.fonteTexto
                        font.pixelSize: Tema.tamanhoRotulo
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Tema.alturaBarra
                        visible: janela.modelo.estado === "baixando"
                        radius: height / 2
                        color: Tema.trilhoBarra
                        Rectangle {
                            width: parent.width * (janela.modelo.progresso ?? 0)
                            height: parent.height
                            radius: height / 2
                            color: Tema.principal
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        visible: janela.modelo.estado === "ausente" || janela.modelo.estado === "baixando"
                        Item { Layout.fillWidth: true }
                        BotaoTexto {
                            visible: janela.modelo.estado === "baixando"
                            texto: qsTr("Cancelar")
                            onAcionado: janela.assistente.cancelarDownload()
                        }
                        BotaoTexto {
                            visible: janela.modelo.estado === "ausente"
                            texto: qsTr("Baixar modelo")
                            principal: true
                            onAcionado: janela.assistente.baixar()
                        }
                    }
                }

                // Pergunta em andamento ou a última resposta.
                ColumnLayout {
                    id: conversa
                    Layout.fillWidth: true
                    Layout.margins: 24
                    spacing: 10
                    visible: janela.pronto && (janela.esperando || janela.ultima !== null)
                    Accessible.role: Accessible.StaticText
                    Accessible.name: textoResposta.text

                    Text {
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        textFormat: Text.PlainText
                        text: qsTr("Você: %1").arg(janela.esperando ? janela.assistente.perguntaPendente
                                                                    : (janela.ultima?.pergunta ?? ""))
                        color: Tema.textoTerciario
                        font.family: Tema.fonteTexto
                        font.pixelSize: Tema.tamanhoTexto
                    }
                    Text {
                        id: textoResposta
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        textFormat: Text.PlainText
                        lineHeight: 1.4
                        text: janela.esperando ? janela.rotuloFerramenta + "…" : (janela.ultima?.texto ?? "")
                        color: janela.esperando ? Tema.textoDiscreto : Tema.texto
                        font.family: Tema.fonteTexto
                        font.pixelSize: Tema.tamanhoTextoGrande
                    }
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
                        model: [["Enter", qsTr("enviar")], ["Esc", qsTr("fechar")]]
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
                        text: qsTr("Atalho: %1").arg("<font color='" + Tema.textoSecundario + "'><b>Super + A</b></font>")
                        color: Tema.textoDiscreto
                        font.family: Tema.fonteTexto
                        font.pixelSize: Tema.tamanhoRotulo
                    }
                }
            }
        }
    }
}
