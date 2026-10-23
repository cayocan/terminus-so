import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import "tema"

// Navegador de pastas (docs/design/telas/Pastas.dc.html): janela com barra de título própria e botões
// à direita, histórico, caminho clicável, busca, modos ícones e lista, barra lateral e rodapé.
FloatingWindow {
    id: janela

    // var (e não Pastas): Pastas cria esta janela, e o tipo explícito faria uma dependência circular.
    required property var pastas
    property string caminhoInicial
    property string caminho
    property var historico: []
    property var futuro: []
    property string modo: "icones"
    property string busca: ""
    // Índices selecionados em itens.
    property var selecao: []
    property var itens: []
    property string mensagem
    property bool mensagemErro: false
    property string livreAqui
    property string livreSistema

    readonly property var localidade: Qt.locale("pt_BR")
    readonly property bool naLixeira: caminho === pastas.lixeira || caminho.startsWith(pastas.lixeira + "/")
    readonly property string nomeAtual: caminho === pastas.inicio ? qsTr("Início")
                                      : caminho === pastas.lixeira ? qsTr("Lixeira")
                                      : caminho === "/" ? qsTr("Disco do sistema")
                                      : caminho.substring(caminho.lastIndexOf("/") + 1)

    function navegar(destino, semHistorico) {
        if (destino === caminho) return
        if (!semHistorico && caminho !== "") {
            historico = historico.concat([caminho])
            futuro = []
        }
        caminho = destino
        busca = ""
        campoBusca.text = ""
        selecao = []
    }
    function voltar() {
        if (historico.length === 0) return
        futuro = [caminho].concat(futuro)
        const destino = historico[historico.length - 1]
        historico = historico.slice(0, -1)
        navegar(destino, true)
    }
    function avancar() {
        if (futuro.length === 0) return
        historico = historico.concat([caminho])
        const destino = futuro[0]
        futuro = futuro.slice(1)
        navegar(destino, true)
    }
    function abrirItem(i) {
        const item = itens[i]
        if (!item) return
        if (item.pasta) navegar(item.caminho)
        else Quickshell.execDetached(["xdg-open", item.caminho])
    }

    // Partes do caminho para a barra de navegação: dentro da pasta pessoal começa em "Início",
    // dentro da lixeira em "Lixeira".
    function partesCaminho() {
        if (naLixeira) {
            const partes = [{ nome: qsTr("Lixeira"), caminho: pastas.lixeira }]
            let atual = pastas.lixeira
            for (const nome of caminho.substring(pastas.lixeira.length).split("/").filter(p => p !== "")) {
                atual += "/" + nome
                partes.push({ nome: nome, caminho: atual })
            }
            return partes
        }
        const naPessoal = caminho === pastas.inicio || caminho.startsWith(pastas.inicio + "/")
        const base = naPessoal ? pastas.inicio : ""
        const partes = [{ nome: naPessoal ? qsTr("Início") : qsTr("Disco do sistema"), caminho: naPessoal ? base : "/" }]
        let atual = base
        for (const nome of caminho.substring(base.length).split("/").filter(p => p !== "")) {
            atual += "/" + nome
            partes.push({ nome: nome, caminho: atual })
        }
        return partes
    }

    function selecionar(indice, somar) {
        if (!somar) selecao = [indice]
        else if (selecao.includes(indice)) selecao = selecao.filter(i => i !== indice)
        else selecao = selecao.concat([indice])
        moldura.forceActiveFocus()
    }
    function selecionados() { return selecao.map(i => itens[i]).filter(i => i !== undefined) }
    function nomesAqui() { return itens.map(i => i.nome) }

    function avisar(texto, erro) {
        mensagem = texto
        mensagemErro = erro
        limpaMensagem.restart()
    }

    function copiar(recortar) {
        const lista = selecionados()
        if (lista.length === 0 || naLixeira) return
        pastas.areaTransferencia = { recortar: recortar, itens: lista.map(i => ({ caminho: i.caminho, pasta: i.pasta })) }
        const n = lista.length
        avisar(recortar ? (n === 1 ? qsTr("1 item recortado") : qsTr("%1 itens recortados").arg(n))
                        : (n === 1 ? qsTr("1 item copiado") : qsTr("%1 itens copiados").arg(n)), false)
    }
    function colar() {
        const transferencia = pastas.areaTransferencia
        if (!transferencia || naLixeira) return
        operacoes.colar(transferencia.itens, caminho, transferencia.recortar, nomesAqui())
        // O que foi recortado só pode ser colado uma vez.
        if (transferencia.recortar) pastas.areaTransferencia = null
    }
    function pedirNovaPasta() {
        if (naLixeira) return
        dialogo.pedirNome(qsTr("Nova pasta"), operacoes.nomeLivre(qsTr("Nova pasta"), nomesAqui(), true), qsTr("Criar"),
                          nome => {
                              if (nomesAqui().includes(nome)) avisar(qsTr("Já existe um item chamado “%1” aqui.").arg(nome), true)
                              else operacoes.novaPasta(caminho, nome)
                          })
    }
    function pedirRenomear() {
        const lista = selecionados()
        if (lista.length !== 1 || naLixeira) return
        const item = lista[0]
        dialogo.pedirNome(qsTr("Renomear"), item.nome, qsTr("Renomear"), nome => {
            if (nome === item.nome) return
            if (nome.includes("/")) avisar(qsTr("O nome não pode ter “/”."), true)
            else if (nomesAqui().includes(nome)) avisar(qsTr("Já existe um item chamado “%1” aqui.").arg(nome), true)
            else operacoes.renomear(item.caminho, nome)
        })
    }
    function paraLixeira() {
        const lista = selecionados()
        if (lista.length === 0 || naLixeira) return
        operacoes.moverParaLixeira(lista.map(i => i.caminho))
    }
    function restaurar() {
        const lista = selecionados()
        if (lista.length === 0 || caminho !== pastas.lixeira) return
        operacoes.restaurar(lista.map(i => i.nome))
    }
    function pedirEsvaziar() {
        if (itens.length === 0) return
        dialogo.confirmar(qsTr("Esvaziar lixeira"),
                          qsTr("Os itens da lixeira serão apagados para sempre. Não dá para desfazer."),
                          qsTr("Esvaziar"), () => operacoes.esvaziarLixeira())
    }

    function menuItem(indice, x, y) {
        if (!selecao.includes(indice)) selecao = [indice]
        const itensMenu = naLixeira ? [
            { texto: qsTr("Restaurar"), acao: () => restaurar() }
        ] : [
            { texto: qsTr("Abrir"), acao: () => abrirItem(indice) },
            { texto: qsTr("Copiar"), acao: () => copiar(false) },
            { texto: qsTr("Recortar"), acao: () => copiar(true) }
        ].concat(selecao.length === 1 ? [{ texto: qsTr("Renomear"), acao: () => pedirRenomear() }] : [])
         .concat([{ texto: qsTr("Mover para a Lixeira"), perigo: true, acao: () => paraLixeira() }])
        menu.abrir(x, y, itensMenu)
    }
    function menuFundo(x, y) {
        selecao = []
        const itensMenu = naLixeira ? [
            { texto: qsTr("Esvaziar lixeira"), perigo: true, acao: () => pedirEsvaziar() }
        ] : [
            { texto: qsTr("Nova pasta"), acao: () => pedirNovaPasta() }
        ].concat(pastas.areaTransferencia ? [{ texto: qsTr("Colar"), acao: () => colar() }] : [])
        menu.abrir(x, y, itensMenu)
    }

    function tamanhoLegivel(bytes) {
        const unidades = ["B", "KB", "MB", "GB", "TB"]
        let i = 0
        while (bytes >= 1024 && i < unidades.length - 1) { bytes /= 1024; i++ }
        return (i === 0 ? bytes : bytes.toLocaleString(localidade, "f", 1)) + " " + unidades[i]
    }

    function tipo(sufixo, pasta) {
        if (pasta) return { icone: Icones.pasta, cor: Tema.corPasta, fundo: Tema.pastaSuave }
        const s = sufixo.toLowerCase()
        const arquivo = icone => ({ icone: icone, cor: Tema.textoTerciario, fundo: Tema.superficieNeutra })
        if (["png", "jpg", "jpeg", "gif", "webp", "svg", "bmp"].includes(s)) return { icone: Icones.imagem, cor: Tema.principal, fundo: Tema.destaqueSuave }
        if (["ogg", "mp3", "flac", "wav", "opus", "m4a"].includes(s)) return { icone: Icones.audio, cor: Tema.principal, fundo: Tema.destaqueSuave }
        if (["mp4", "mkv", "webm", "avi", "mov"].includes(s)) return { icone: Icones.video, cor: Tema.principal, fundo: Tema.destaqueSuave }
        if (["zip", "tar", "gz", "xz", "zst", "7z", "rar"].includes(s)) return arquivo(Icones.compactado)
        if (["deb", "appimage", "flatpakref"].includes(s)) return { icone: Icones.pacote, cor: Tema.corPasta, fundo: Tema.pastaSuave }
        return arquivo(Icones.documento)
    }

    function montarItens() {
        if (modelo.status !== FolderListModel.Ready) return
        const filtro = busca.trim().toLowerCase()
        const lista = []
        for (let i = 0; i < modelo.count; i++) {
            const nome = modelo.get(i, "fileName")
            if (filtro !== "" && !nome.toLowerCase().includes(filtro)) continue
            const pasta = modelo.get(i, "fileIsDir")
            const t = tipo(modelo.get(i, "fileSuffix"), pasta)
            lista.push({
                nome: nome, caminho: modelo.get(i, "filePath"), pasta: pasta,
                icone: t.icone, cor: t.cor, fundoIcone: t.fundo,
                meta: pasta ? qsTr("Pasta") : tamanhoLegivel(modelo.get(i, "fileSize")),
                modificado: modelo.get(i, "fileModified").toLocaleString(localidade, "dd/MM/yyyy HH:mm")
            })
        }
        itens = lista
        selecao = []
    }

    title: nomeAtual + " — Pastas"
    implicitWidth: Math.min(Tema.larguraJanela, (screen ? screen.width : 1920) * 0.82)
    implicitHeight: Math.min(Tema.alturaJanela, (screen ? screen.height : 1080) * 0.8)
    minimumSize: Qt.size(720, 480)
    color: "transparent"

    Component.onCompleted: navegar(caminhoInicial, true)
    onBuscaChanged: montarItens()
    onCaminhoChanged: {
        espacoLivre.running = false
        espacoLivre.running = true
    }

    OperacoesArquivo {
        id: operacoes
        onConcluido: erros => {
            if (erros.length > 0) janela.avisar(erros[0], true)
        }
    }

    Timer {
        id: limpaMensagem
        interval: 6000
        onTriggered: janela.mensagem = ""
    }

    FolderListModel {
        id: modelo
        folder: "file://" + janela.caminho
        showDirsFirst: true
        showDotAndDotDot: false
        sortCaseSensitive: false
        onStatusChanged: janela.montarItens()
        onCountChanged: janela.montarItens()
    }

    // Espaço livre: no disco da pasta atual (rodapé) e no disco do sistema (barra lateral).
    Process {
        id: espacoLivre
        command: ["df", "-B1", "--output=avail", janela.caminho || "/", "/"]
        stdout: StdioCollector {
            onStreamFinished: {
                const linhas = text.trim().split("\n")
                if (linhas.length >= 3) {
                    janela.livreAqui = janela.tamanhoLegivel(parseFloat(linhas[1]))
                    janela.livreSistema = janela.tamanhoLegivel(parseFloat(linhas[2]))
                }
            }
        }
    }

    Rectangle {
        id: moldura
        anchors.fill: parent
        radius: janela.maximized ? 0 : Tema.raioJanela
        color: Tema.vidroJanela
        border.color: Qt.alpha(Tema.principal, 0.3)
        clip: true

        focus: true
        Keys.onPressed: evento => {
            if (evento.key === Qt.Key_Backspace || (evento.key === Qt.Key_Left && evento.modifiers & Qt.AltModifier)) janela.voltar()
            else if (evento.key === Qt.Key_Right && evento.modifiers & Qt.AltModifier) janela.avancar()
            else if (evento.key === Qt.Key_Return || evento.key === Qt.Key_Enter) { if (janela.selecao.length === 1) janela.abrirItem(janela.selecao[0]) }
            else if (evento.key === Qt.Key_F && evento.modifiers & Qt.ControlModifier) campoBusca.forceActiveFocus()
            else if (evento.key === Qt.Key_C && evento.modifiers & Qt.ControlModifier) janela.copiar(false)
            else if (evento.key === Qt.Key_X && evento.modifiers & Qt.ControlModifier) janela.copiar(true)
            else if (evento.key === Qt.Key_V && evento.modifiers & Qt.ControlModifier) janela.colar()
            else if (evento.key === Qt.Key_A && evento.modifiers & Qt.ControlModifier) janela.selecao = janela.itens.map((_, i) => i)
            else if (evento.key === Qt.Key_N && evento.modifiers & Qt.ControlModifier && evento.modifiers & Qt.ShiftModifier) janela.pedirNovaPasta()
            else if (evento.key === Qt.Key_F2) janela.pedirRenomear()
            else if (evento.key === Qt.Key_Delete) janela.paraLixeira()
            else if (evento.key === Qt.Key_Escape) janela.selecao = []
            else return
            evento.accepted = true
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 1
            spacing: 0

            BarraTitulo {
                Layout.fillWidth: true
                janelaAlvo: janela
                titulo: qsTr("Pastas")
                icone: Icones.pasta
                onFecharPedido: janela.pastas.fechar()
            }

            // ---------- Barra de ferramentas ----------
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: Tema.alturaFerramentas
                Layout.leftMargin: 16
                Layout.rightMargin: 16
                spacing: 12

                BotaoIcone {
                    nome: qsTr("Voltar")
                    icone: Icones.voltar
                    opacity: janela.historico.length > 0 ? 1 : 0.5
                    onAcionado: janela.voltar()
                }
                BotaoIcone {
                    nome: qsTr("Avançar")
                    icone: Icones.avancar
                    opacity: janela.futuro.length > 0 ? 1 : 0.5
                    onAcionado: janela.avancar()
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Tema.alvoMinimo
                    radius: Tema.raioBotaoArea
                    color: Tema.superficieNeutra
                    border.color: Qt.rgba(156 / 255, 201 / 255, 224 / 255, 0.14)
                    clip: true
                    Accessible.role: Accessible.Grouping
                    Accessible.name: qsTr("Caminho")

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8
                        Repeater {
                            model: janela.partesCaminho()
                            delegate: Row {
                                required property var modelData
                                required property int index
                                readonly property bool ultima: index === janela.partesCaminho().length - 1
                                spacing: 8
                                Text {
                                    visible: index > 0
                                    text: "›"
                                    color: Tema.textoDesativado
                                    font.family: Tema.fonteTexto
                                    font.pixelSize: Tema.tamanhoTextoMenor
                                }
                                Text {
                                    text: modelData.nome
                                    color: ultima ? Tema.texto : (toqueParte.containsMouse ? Tema.linkHover : Tema.textoTerciario)
                                    font.family: Tema.fonteTexto
                                    font.weight: ultima ? Font.DemiBold : Font.Normal
                                    font.pixelSize: Tema.tamanhoTextoMenor
                                    MouseArea {
                                        id: toqueParte
                                        anchors.fill: parent
                                        enabled: !ultima
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: janela.navegar(modelData.caminho)
                                    }
                                }
                            }
                        }
                    }
                }

                // Modo de visualização. "Colunas" ainda não existe e aparece desativado.
                Rectangle {
                    Layout.preferredWidth: modos.implicitWidth + 6
                    Layout.preferredHeight: Tema.alvoMinimo
                    radius: Tema.raioBotaoArea
                    color: Tema.superficieNeutra
                    border.color: Qt.rgba(156 / 255, 201 / 255, 224 / 255, 0.14)
                    Accessible.role: Accessible.Grouping
                    Accessible.name: qsTr("Modo de visualização")

                    Row {
                        id: modos
                        anchors.centerIn: parent
                        Repeater {
                            model: [
                                { id: "icones", nome: qsTr("Ícones"), icone: Icones.grade },
                                { id: "lista", nome: qsTr("Lista"), icone: Icones.lista },
                                { id: "colunas", nome: qsTr("Colunas (em breve)"), icone: Icones.colunas }
                            ]
                            delegate: Rectangle {
                                required property var modelData
                                readonly property bool ativo: janela.modo === modelData.id
                                width: Tema.alvoMinimo
                                height: Tema.alvoMinimo - 6
                                radius: 9
                                color: ativo ? Tema.modoAtivo : "transparent"
                                opacity: modelData.id === "colunas" ? 0.4 : 1
                                Accessible.role: Accessible.Button
                                Accessible.name: modelData.nome
                                Accessible.checked: ativo
                                Icone {
                                    anchors.centerIn: parent
                                    caminhos: modelData.icone
                                    tamanho: 17
                                    espessura: 1.8
                                    cor: parent.ativo ? Tema.principal : Tema.textoTerciario
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    enabled: modelData.id !== "colunas"
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: janela.modo = modelData.id
                                }
                            }
                        }
                    }
                }

                BotaoTexto {
                    visible: janela.caminho === janela.pastas.lixeira
                    texto: qsTr("Esvaziar lixeira")
                    perigo: true
                    principal: janela.itens.length > 0
                    onAcionado: janela.pedirEsvaziar()
                }

                TextField {
                    id: campoBusca
                    Layout.preferredWidth: Tema.larguraBuscaPasta
                    Layout.preferredHeight: Tema.alvoMinimo
                    placeholderText: qsTr("Buscar em %1").arg(janela.nomeAtual)
                    placeholderTextColor: Tema.textoMarcador
                    color: Tema.texto
                    font.family: Tema.fonteTexto
                    font.pixelSize: Tema.tamanhoTextoMenor
                    leftPadding: 40
                    background: Rectangle {
                        radius: Tema.raioBotaoArea
                        color: Tema.superficieNeutra
                        border.color: campoBusca.activeFocus ? Tema.principal : Tema.bordaCampo
                        Icone {
                            anchors.left: parent.left
                            anchors.leftMargin: 14
                            anchors.verticalCenter: parent.verticalCenter
                            caminhos: Icones.busca
                            tamanho: 16
                            espessura: 2
                            cor: Tema.textoDiscreto
                        }
                    }
                    onTextChanged: janela.busca = text
                    Keys.onEscapePressed: { text = ""; moldura.forceActiveFocus() }
                }
            }
            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Tema.linhaDivisoria }

            // ---------- Lateral e conteúdo ----------
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                LateralPastas {
                    Layout.preferredWidth: Tema.larguraLateral
                    Layout.fillHeight: true
                    pastas: janela.pastas
                    caminho: janela.caminho
                    livreSistema: janela.livreSistema
                    onNavegar: destino => janela.navegar(destino)
                }
                Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: Tema.linhaDivisoria }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 0

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        // Clique no vazio: o esquerdo limpa a seleção, o direito abre o menu da pasta.
                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: mouse => {
                                moldura.forceActiveFocus()
                                if (mouse.button === Qt.RightButton) {
                                    const p = mapToItem(moldura, mouse.x, mouse.y)
                                    janela.menuFundo(p.x, p.y)
                                } else janela.selecao = []
                            }
                        }

                        GridView {
                            id: grade
                            anchors.fill: parent
                            anchors.leftMargin: 28
                            anchors.rightMargin: 16
                            anchors.topMargin: 24
                            visible: janela.modo === "icones"
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds
                            readonly property int colunas: Math.max(1, Math.floor(width / Tema.larguraMinimaItemPasta))
                            cellWidth: width / colunas
                            cellHeight: Tema.alturaItemPasta + Tema.espacoAtalhos
                            model: janela.itens
                            delegate: Item {
                                required property var modelData
                                required property int index
                                width: grade.cellWidth
                                height: grade.cellHeight
                                ItemPasta {
                                    anchors.fill: parent
                                    anchors.rightMargin: Tema.espacoAtalhos
                                    anchors.bottomMargin: Tema.espacoAtalhos
                                    entrada: modelData
                                    selecionado: janela.selecao.includes(index)
                                    onSelecionar: somar => janela.selecionar(index, somar)
                                    onMenuPedido: (mx, my) => {
                                        const p = mapToItem(moldura, mx, my)
                                        janela.menuItem(index, p.x, p.y)
                                    }
                                    onAbrir: janela.abrirItem(index)
                                }
                            }
                        }

                        ListView {
                            anchors.fill: parent
                            anchors.margins: 16
                            visible: janela.modo === "lista"
                            clip: true
                            spacing: 2
                            boundsBehavior: Flickable.StopAtBounds
                            model: janela.itens
                            delegate: LinhaPasta {
                                required property var modelData
                                required property int index
                                width: ListView.view.width
                                entrada: modelData
                                selecionado: janela.selecao.includes(index)
                                onSelecionar: somar => janela.selecionar(index, somar)
                                onMenuPedido: (mx, my) => {
                                    const p = mapToItem(moldura, mx, my)
                                    janela.menuItem(index, p.x, p.y)
                                }
                                onAbrir: janela.abrirItem(index)
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: janela.itens.length === 0 && modelo.status === FolderListModel.Ready
                            text: janela.busca !== "" ? qsTr("Nada encontrado para “%1”.").arg(janela.busca) : qsTr("Pasta vazia.")
                            color: Tema.textoDiscreto
                            font.family: Tema.fonteTexto
                            font.pixelSize: Tema.tamanhoTexto
                        }
                    }

                    Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Tema.linhaDivisoria }
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Tema.alturaRodape
                        Layout.leftMargin: 24
                        Layout.rightMargin: 24
                        Text {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            text: janela.mensagem !== "" ? janela.mensagem
                                  : (janela.itens.length === 1 ? qsTr("1 item") : qsTr("%1 itens").arg(janela.itens.length))
                                    + (janela.selecao.length === 1 ? qsTr(" · 1 selecionado")
                                       : janela.selecao.length > 1 ? qsTr(" · %1 selecionados").arg(janela.selecao.length) : "")
                                    + (operacoes.ocupado ? qsTr(" · trabalhando…") : "")
                            color: janela.mensagem !== "" && janela.mensagemErro ? Tema.erroTexto : Tema.textoDiscreto
                            font.family: Tema.fonteTexto
                            font.pixelSize: Tema.tamanhoRotulo
                        }
                        Text {
                            visible: janela.livreAqui !== ""
                            text: qsTr("%1 livres").arg(janela.livreAqui)
                            color: Tema.textoDiscreto
                            font.family: Tema.fonteTexto
                            font.pixelSize: Tema.tamanhoRotulo
                        }
                    }
                }
            }
        }

        MenuContexto {
            id: menu
            anchors.fill: parent
        }

        DialogoPasta {
            id: dialogo
            anchors.fill: parent
            onFechado: moldura.forceActiveFocus()
        }
    }

    BordasRedimensionar {
        anchors.fill: parent
        janelaAlvo: janela
    }
}
