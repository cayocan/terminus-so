import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "tema"

// Página Usuários e segurança: estado do servidor do sistema, nível de permissão de cada ferramenta e o
// histórico das ações. Os níveis escolhidos ficam em ~/.config/terminus/pessoal/permissoes.json; as
// ferramentas críticas não descem de "senha" (o servidor garante isso também).
ColumnLayout {
    id: pagina

    property var servidor
    property var ferramentas: []
    property var escolhas: ({})
    property var historico: []
    // permissoes.json ilegível: não grava por cima (é da camada pessoal).
    property bool somenteLeitura: false

    readonly property var niveis: [
        { id: "livre", nome: qsTr("Livre") },
        { id: "confirmacao", nome: qsTr("Confirmar") },
        { id: "senha", nome: qsTr("Senha") }
    ]
    readonly property var nomesGrupos: ({
        sistema: qsTr("Sistema"), apps: qsTr("Apps"), janelas: qsTr("Janelas"), arquivos: qsTr("Arquivos"),
        interface: qsTr("Interface"), areas: qsTr("Áreas de atalho"), energia: qsTr("Energia"), historico: qsTr("Histórico")
    })
    readonly property var nomesResultado: ({ feito: qsTr("feito"), negado: qsTr("negado"), erro: qsTr("erro") })
    readonly property var localidade: Qt.locale("pt_BR")

    function definir(ferramenta, nivel) {
        const copia = Object.assign({}, escolhas)
        if (nivel === ferramenta.padrao) delete copia[ferramenta.nome]
        else copia[ferramenta.nome] = nivel
        escolhas = copia
        if (somenteLeitura) return
        arquivoPermissoes.setText(JSON.stringify({ versao: 1, ferramentas: copia }, null, 2))
        lerFerramentas.running = true
    }

    function lerHistorico(texto) {
        historico = texto.split("\n").filter(l => l !== "").slice(-100).reverse().map(l => {
            try { return JSON.parse(l) } catch (e) { return null }
        }).filter(r => r !== null)
    }

    spacing: 26

    TituloPagina {
        Layout.fillWidth: true
        titulo: qsTr("Usuários e segurança")
        descricao: qsTr("Tudo que o assistente e as IAs de programação fazem no sistema passa pelo servidor do Terminus. Cada ação tem um nível: livre, pede confirmação ou pede sua senha. Todas ficam no histórico.")
    }

    // ---------- Estado do servidor ----------
    RowLayout {
        spacing: 10
        Rectangle {
            Layout.preferredWidth: 10
            Layout.preferredHeight: 10
            radius: 5
            color: pagina.servidor && pagina.servidor.conectado ? Tema.sucesso : Tema.erro
        }
        Text {
            text: pagina.servidor && pagina.servidor.conectado
                  ? qsTr("Servidor do sistema ligado")
                  : qsTr("Servidor do sistema desligado. As ações que pedem confirmação são negadas até ele voltar.")
            color: Tema.textoSecundario
            font.family: Tema.fonteTexto
            font.pixelSize: Tema.tamanhoTextoMenor
        }
    }

    // ---------- Permissões ----------
    Text {
        text: qsTr("PERMISSÕES")
        color: Tema.principal
        font.family: Tema.fonteTitulo
        font.weight: Font.DemiBold
        font.pixelSize: Tema.tamanhoSecao
        font.letterSpacing: Tema.espacamentoSecao
    }

    Repeater {
        model: Object.keys(pagina.nomesGrupos).filter(g => pagina.ferramentas.some(f => f.grupo === g))
        delegate: ColumnLayout {
            id: grupo
            required property string modelData
            Layout.fillWidth: true
            spacing: 4

            Text {
                Layout.topMargin: 8
                text: pagina.nomesGrupos[grupo.modelData]
                color: Tema.textoDiscreto
                font.family: Tema.fonteTexto
                font.weight: Font.DemiBold
                font.pixelSize: Tema.tamanhoLegenda
                font.letterSpacing: Tema.espacamentoRotulo
                font.capitalization: Font.AllUppercase
            }

            Repeater {
                model: pagina.ferramentas.filter(f => f.grupo === grupo.modelData)
                delegate: RowLayout {
                    id: linha
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: Tema.alvoMinimo + 4
                    spacing: 16

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            text: linha.modelData.nome
                            color: Tema.texto
                            font.family: Tema.fonteTexto
                            font.weight: Font.DemiBold
                            font.pixelSize: Tema.tamanhoTextoMenor
                        }
                        Text {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            text: linha.modelData.descricao
                            color: Tema.textoDiscreto
                            font.family: Tema.fonteTexto
                            font.pixelSize: Tema.tamanhoLegenda
                        }
                    }

                    // Seletor de nível em pílulas.
                    Row {
                        spacing: 4
                        Repeater {
                            model: pagina.niveis
                            delegate: Rectangle {
                                required property var modelData
                                readonly property bool ativo: linha.modelData.nivel === modelData.id
                                readonly property bool bloqueado: linha.modelData.critica && modelData.id !== "senha"
                                width: rotulo.implicitWidth + 24
                                height: 32
                                radius: 16
                                color: ativo ? Tema.selecaoFundo : (toque.containsMouse && !bloqueado ? Tema.hover : "transparent")
                                border.color: ativo ? Tema.principal : Tema.bordaNeutra
                                opacity: bloqueado ? 0.35 : 1
                                Accessible.role: Accessible.RadioButton
                                Accessible.name: linha.modelData.nome + ": " + modelData.nome
                                Accessible.checked: ativo
                                Text {
                                    id: rotulo
                                    anchors.centerIn: parent
                                    text: modelData.nome
                                    color: parent.ativo ? Tema.principalClaro : Tema.textoSecundario
                                    font.family: Tema.fonteTexto
                                    font.pixelSize: Tema.tamanhoRotulo
                                }
                                MouseArea {
                                    id: toque
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    enabled: !parent.bloqueado && !parent.ativo
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: pagina.definir(linha.modelData, modelData.id)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ---------- Histórico ----------
    Text {
        Layout.topMargin: 12
        text: qsTr("HISTÓRICO")
        color: Tema.principal
        font.family: Tema.fonteTitulo
        font.weight: Font.DemiBold
        font.pixelSize: Tema.tamanhoSecao
        font.letterSpacing: Tema.espacamentoSecao
    }
    Text {
        visible: pagina.historico.length === 0
        text: qsTr("Nenhuma ação ainda.")
        color: Tema.textoDiscreto
        font.family: Tema.fonteTexto
        font.pixelSize: Tema.tamanhoTextoMenor
    }
    Repeater {
        model: pagina.historico
        delegate: RowLayout {
            required property var modelData
            Layout.fillWidth: true
            spacing: 14
            Text {
                Layout.preferredWidth: 120
                text: new Date(modelData.quando * 1000).toLocaleString(pagina.localidade, "dd/MM HH:mm:ss")
                color: Tema.textoDiscreto
                font.family: Tema.fonteTexto
                font.pixelSize: Tema.tamanhoRotulo
            }
            Text {
                Layout.preferredWidth: 70
                text: pagina.nomesResultado[modelData.resultado] ?? modelData.resultado
                color: modelData.resultado === "feito" ? Tema.sucessoTexto
                     : modelData.resultado === "negado" ? Tema.atencaoTexto : Tema.erroTexto
                font.family: Tema.fonteTexto
                font.weight: Font.DemiBold
                font.pixelSize: Tema.tamanhoRotulo
            }
            Text {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: modelData.ferramenta + (Object.keys(modelData.argumentos ?? {}).length
                      ? " " + JSON.stringify(modelData.argumentos) : "")
                      + (modelData.detalhe && modelData.resultado !== "feito" ? " · " + modelData.detalhe : "")
                textFormat: Text.PlainText
                color: Tema.textoSecundario
                font.family: Tema.fonteTexto
                font.pixelSize: Tema.tamanhoRotulo
            }
            Text {
                text: modelData.cliente
                textFormat: Text.PlainText
                color: Tema.textoDiscreto
                font.family: Tema.fonteTexto
                font.pixelSize: Tema.tamanhoLegenda
            }
        }
    }

    Process {
        id: lerFerramentas
        running: true
        command: ["terminus-mcp", "ferramentas"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { pagina.ferramentas = JSON.parse(text) } catch (e) { pagina.ferramentas = [] }
            }
        }
    }

    FileView {
        id: arquivoPermissoes
        path: Quickshell.env("HOME") + "/.config/terminus/pessoal/permissoes.json"
        printErrors: false
        onLoaded: {
            try { pagina.escolhas = JSON.parse(text()).ferramentas ?? {} } catch (e) { pagina.somenteLeitura = true }
        }
    }

    FileView {
        path: Quickshell.env("HOME") + "/.local/state/terminus/historico.jsonl"
        printErrors: false
        watchChanges: true
        onLoaded: pagina.lerHistorico(text())
        onFileChanged: reload()
    }
}
