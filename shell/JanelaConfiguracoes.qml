import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import Quickshell
import "tema"

// Configurações (docs/design/telas/Config.dc.html): janela com barra de título própria, categorias com
// busca à esquerda e a página da categoria à direita.
FloatingWindow {
    id: janela

    // var (e não Configuracoes): Configuracoes cria esta janela.
    required property var configuracoes
    property string categoria: "aparencia"
    property string filtro: ""

    readonly property var categoriaAtual: configuracoes.categorias.find(c => c.id === categoria) ?? configuracoes.categorias[0]
    readonly property var visiveis: configuracoes.categorias.filter(c => normalizar(c.nome).includes(normalizar(filtro.trim())))

    // O que cada categoria ainda sem página vai ter, e em que fase do ROADMAP.md.
    readonly property var planos: ({
        ia: [qsTr("fase 5"), [qsTr("Escolher a IA de programação padrão (Claude Code) e ligar outras por conectores"),
                              qsTr("Sempre pela sua conta, nunca por API paga"),
                              qsTr("Pedir senha para ativar funções criadas pela IA")]],
        areas: [qsTr("fase 2"), [qsTr("Fixar e tirar apps da dock"), qsTr("Escolher outras pastas para abrir em leque"),
                                 qsTr("Organizar as áreas sozinho")]],
        rede: [qsTr("fase 2"), [qsTr("Wi-Fi e cabo"), qsTr("Bluetooth")]],
        som: [qsTr("fase 2"), [qsTr("Saída e entrada de áudio"), qsTr("Volume por app"), qsTr("Microfone para o assistente")]],
        telas: [qsTr("fase 2"), [qsTr("Resolução, taxa de atualização e escala"), qsTr("Vários monitores")]],
        usuarios: [qsTr("fases 3 e 8"), [qsTr("Senha no boot e voz na tela de bloqueio"),
                                         qsTr("Nível de permissão de cada ação do sistema: livre, confirmação por voz ou senha"),
                                         qsTr("Histórico de tudo que o sistema fez")]],
        atualizacoes: [qsTr("fase 7"), [qsTr("Atualizar a base pelo GitHub, com snapshot antes"),
                                        qsTr("Conflitos com a camada pessoal perguntados a você"),
                                        qsTr("Exportar o sistema para um Git seu ou gerar uma ISO pessoal")]],
        jogos: [qsTr("fase 2"), [qsTr("Steam com Proton e Proton-GE"), qsTr("Wine e Bottles"),
                                 qsTr("VM Windows de reserva (KVM + WinApps)")]]
    })

    function normalizar(texto) {
        return texto.normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase()
    }

    title: qsTr("Configurações")
    implicitWidth: Math.min(Tema.larguraConfig, (screen ? screen.width : 1920) * 0.85)
    implicitHeight: Math.min(Tema.alturaConfig, (screen ? screen.height : 1080) * 0.85)
    minimumSize: Qt.size(820, 540)
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        radius: janela.maximized ? 0 : Tema.raioJanela
        color: Tema.vidroJanela
        border.color: Qt.alpha(Tema.principal, 0.3)
        clip: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 1
            spacing: 0

            BarraTitulo {
                Layout.fillWidth: true
                janelaAlvo: janela
                titulo: qsTr("Configurações")
                icone: Icones.configuracoes
                onFecharPedido: janela.configuracoes.fechar()
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                // ---------- Categorias ----------
                ColumnLayout {
                    // Um layout herda o "fillWidth" dos filhos; aqui a largura é fixa.
                    Layout.fillWidth: false
                    Layout.preferredWidth: Tema.larguraCategorias - 28
                    Layout.maximumWidth: Tema.larguraCategorias - 28
                    Layout.fillHeight: true
                    Layout.margins: 14
                    Layout.topMargin: 18
                    spacing: 4

                    TextField {
                        id: busca
                        Layout.fillWidth: true
                        Layout.preferredHeight: Tema.alvoMinimo
                        Layout.bottomMargin: 10
                        placeholderText: qsTr("Buscar configuração")
                        placeholderTextColor: Tema.textoMarcador
                        color: Tema.texto
                        font.family: Tema.fonteTexto
                        font.pixelSize: Tema.tamanhoTextoMenor
                        leftPadding: 40
                        Accessible.name: qsTr("Buscar configuração")
                        background: Rectangle {
                            radius: Tema.raioBotaoArea
                            color: Tema.superficieNeutra
                            border.color: busca.activeFocus ? Tema.principal : Tema.bordaCampo
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
                        onTextChanged: janela.filtro = text
                        onAccepted: if (janela.visiveis.length > 0) janela.categoria = janela.visiveis[0].id
                    }

                    Repeater {
                        model: janela.visiveis
                        delegate: Rectangle {
                            id: itemCategoria
                            required property var modelData
                            readonly property bool ativa: janela.categoria === modelData.id
                            Layout.fillWidth: true
                            Layout.preferredHeight: Tema.alturaCategoria
                            radius: Tema.raioCategoria
                            color: ativa ? Qt.alpha(Tema.principal, 0.14) : (toqueCat.containsMouse ? Qt.rgba(1, 1, 1, 0.05) : "transparent")
                            Accessible.role: Accessible.PageTab
                            Accessible.name: modelData.nome
                            Accessible.selected: ativa

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 14
                                anchors.rightMargin: 14
                                spacing: 12
                                Icone {
                                    caminhos: modelData.icone
                                    tamanho: 18
                                    espessura: 1.7
                                    cor: itemCategoria.ativa ? Tema.textoTitulo : Tema.textoSecundario
                                }
                                Text {
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                    text: modelData.nome
                                    color: itemCategoria.ativa ? Tema.textoTitulo : Tema.textoSecundario
                                    font.family: Tema.fonteTexto
                                    font.weight: itemCategoria.ativa ? Font.DemiBold : Font.Normal
                                    font.pixelSize: Tema.tamanhoCategoria
                                }
                            }
                            MouseArea {
                                id: toqueCat
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: janela.categoria = modelData.id
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }
                }

                Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: Tema.linhaDivisoria }

                // ---------- Página ----------
                Flickable {
                    id: rolagem
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentHeight: pagina.height + 2 * Tema.preenchimentoConfigV
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Loader {
                        id: pagina
                        x: Tema.preenchimentoConfigH
                        y: Tema.preenchimentoConfigV
                        width: rolagem.width - 2 * Tema.preenchimentoConfigH
                        sourceComponent: janela.categoriaAtual.id === "aparencia" ? aparencia
                                       : janela.categoriaAtual.id === "assistente" ? assistente
                                       : janela.categoriaAtual.id === "conectores" ? conectores
                                       : emBreve
                        onSourceComponentChanged: rolagem.contentY = 0
                    }
                }
            }
        }
    }

    Component { id: aparencia; PaginaAparencia { configuracoes: janela.configuracoes } }
    Component { id: assistente; PaginaAssistente { configuracoes: janela.configuracoes } }
    Component { id: conectores; PaginaConectores { configuracoes: janela.configuracoes } }
    Component {
        id: emBreve
        PaginaEmBreve {
            titulo: janela.categoriaAtual.nome
            fase: janela.planos[janela.categoriaAtual.id]?.[0] ?? ""
            itens: janela.planos[janela.categoriaAtual.id]?.[1] ?? []
        }
    }

    BordasRedimensionar {
        anchors.fill: parent
        janelaAlvo: janela
    }
}
