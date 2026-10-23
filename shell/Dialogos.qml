import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import Quickshell
import Quickshell.Wayland
import "tema"

// Diálogos das áreas de atalho (renomear, escolher app, trocar ícone e confirmar exclusão), numa camada acima de tudo e com o
// teclado só para eles enquanto abertos. Abrem quando areas.dialogo recebe um pedido.
PanelWindow {
    id: janela

    required property Areas areas
    readonly property var pedido: areas.dialogo
    readonly property var area: pedido ? areas.buscar(pedido.areaId) : null
    readonly property string tipo: pedido ? pedido.tipo : ""

    function fechar() { areas.dialogo = null }

    visible: pedido !== null && area !== undefined && area !== null
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: Tema.sombraFundo
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "terminus-dialogo"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    MouseArea {
        anchors.fill: parent
        onClicked: janela.fechar()
    }

    Rectangle {
        id: caixa
        anchors.centerIn: parent
        width: Tema.larguraDialogo
        height: conteudo.implicitHeight + 2 * Tema.preenchimentoPainel
        radius: Tema.raioJanela
        color: Tema.vidroJanela
        border.color: Tema.bordaDestaque
        Accessible.role: Accessible.Dialog

        // Impede que o clique dentro da caixa feche o diálogo.
        MouseArea { anchors.fill: parent }

        Keys.onEscapePressed: janela.fechar()

        ColumnLayout {
            id: conteudo
            anchors.fill: parent
            anchors.margins: Tema.preenchimentoPainel
            spacing: Tema.espaco

            Text {
                Layout.fillWidth: true
                text: janela.tipo === "renomear" ? qsTr("RENOMEAR ÁREA")
                    : janela.tipo === "excluir" ? qsTr("EXCLUIR ÁREA")
                    : janela.tipo === "icone" ? qsTr("ÍCONE DA ÁREA") : qsTr("ADICIONAR ATALHO")
                color: janela.tipo === "excluir" ? Tema.erroTexto : Tema.principal
                font.family: Tema.fonteTitulo
                font.weight: Font.DemiBold
                font.pixelSize: Tema.tamanhoSecao
                font.letterSpacing: Tema.espacamentoSecao
            }

            Text {
                Layout.fillWidth: true
                visible: janela.tipo === "excluir"
                text: !janela.area ? "" : janela.area.atalhos.length === 0
                    ? qsTr("A área “%1” vai ser apagada.").arg(janela.area.nome)
                    : qsTr("A área “%1” e os atalhos dela (%2) vão ser apagados. Os apps continuam instalados.")
                        .arg(janela.area.nome).arg(janela.area.atalhos.length)
                wrapMode: Text.Wrap
                color: Tema.textoSecundario
                font.family: Tema.fonteTexto
                font.pixelSize: Tema.tamanhoTexto
            }

            // Ícones para a área (no pedido de ícone).
            Flow {
                Layout.fillWidth: true
                visible: janela.tipo === "icone"
                spacing: 10
                Repeater {
                    model: janela.tipo === "icone" ? janela.areas.iconesDisponiveis : []
                    delegate: Rectangle {
                        required property string modelData
                        readonly property bool escolhido: janela.area !== null && (janela.area.icone ?? "maleta") === modelData
                        width: Tema.areaMinimizada - 8
                        height: width
                        radius: width / 2
                        color: escolhido ? Tema.selecaoFundo : (toqueIcone.containsMouse ? Tema.hover : Tema.vidroPainel)
                        border.color: escolhido ? Tema.principal : Tema.bordaDestaque
                        Accessible.role: Accessible.RadioButton
                        Accessible.name: modelData
                        Accessible.checked: escolhido
                        Icone {
                            anchors.centerIn: parent
                            caminhos: Icones[modelData]
                            tamanho: 26
                            cor: Tema.principal
                        }
                        MouseArea {
                            id: toqueIcone
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                janela.areas.atualizar(janela.area.id, { icone: modelData })
                                janela.fechar()
                            }
                        }
                    }
                }
            }

            TextField {
                id: campo
                visible: janela.tipo === "renomear" || janela.tipo === "atalho"
                Layout.fillWidth: true
                Layout.preferredHeight: Tema.alvoMinimo + 4
                placeholderText: janela.pedido && janela.pedido.tipo === "atalho" ? qsTr("Buscar app") : qsTr("Nome da área")
                placeholderTextColor: Tema.textoDiscreto
                color: Tema.texto
                font.family: Tema.fonteTexto
                font.pixelSize: Tema.tamanhoTexto
                leftPadding: 14
                background: Rectangle {
                    radius: Tema.raioBotaoArea
                    color: Tema.superficieNeutra
                    border.color: campo.activeFocus ? Tema.principal : Tema.bordaNeutra
                }
                Keys.onEscapePressed: janela.fechar()
                onAccepted: {
                    if (janela.pedido.tipo === "renomear") {
                        if (text.trim() !== "") janela.areas.atualizar(janela.area.id, { nome: text.trim() })
                        janela.fechar()
                    } else if (resultados.count > 0) {
                        janela.areas.adicionarAtalho(janela.area.id, resultados.itemAtIndex(0).entrada.id)
                        janela.fechar()
                    }
                }
            }

            // Lista de apps instalados (só no pedido de atalho).
            ListView {
                id: resultados
                Layout.fillWidth: true
                Layout.preferredHeight: visible ? 360 : 0
                visible: janela.pedido !== null && janela.pedido.tipo === "atalho"
                clip: true
                spacing: 2
                model: {
                    if (!visible) return []
                    const busca = campo.text.trim().toLowerCase()
                    return DesktopEntries.applications.values
                        .filter(e => !e.noDisplay && (busca === "" || e.name.toLowerCase().includes(busca)))
                        .sort((a, b) => a.name.localeCompare(b.name))
                }
                delegate: Rectangle {
                    id: linhaApp
                    required property var modelData
                    readonly property var entrada: modelData
                    readonly property bool jaNaArea: janela.area !== null && janela.area.atalhos.includes(modelData.id)

                    width: ListView.view.width
                    height: Tema.alvoMinimo + 4
                    radius: Tema.raioBotaoArea - 2
                    color: toqueApp.containsMouse ? Tema.hover : "transparent"
                    opacity: jaNaArea ? 0.45 : 1
                    Accessible.role: Accessible.ListItem
                    Accessible.name: modelData.name

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 12
                        Image {
                            Layout.preferredWidth: 28
                            Layout.preferredHeight: 28
                            sourceSize: Qt.size(56, 56)
                            source: linhaApp.modelData.icon !== "" ? Quickshell.iconPath(linhaApp.modelData.icon, true) : ""
                            asynchronous: true
                        }
                        Text {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            text: linhaApp.modelData.name
                            color: Tema.texto
                            font.family: Tema.fonteTexto
                            font.pixelSize: Tema.tamanhoTexto
                        }
                        Text {
                            visible: linhaApp.jaNaArea
                            text: qsTr("já na área")
                            color: Tema.textoDiscreto
                            font.family: Tema.fonteTexto
                            font.pixelSize: Tema.tamanhoLegenda
                        }
                    }
                    MouseArea {
                        id: toqueApp
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: !linhaApp.jaNaArea
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            janela.areas.adicionarAtalho(janela.area.id, linhaApp.modelData.id)
                            janela.fechar()
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 4
                spacing: 10
                Item { Layout.fillWidth: true }

                BotaoTexto {
                    id: botaoCancelar
                    texto: qsTr("Cancelar")
                    onAcionado: janela.fechar()
                    Keys.onEscapePressed: janela.fechar()
                }
                BotaoTexto {
                    visible: janela.tipo === "renomear"
                    texto: qsTr("Salvar")
                    principal: true
                    onAcionado: campo.accepted()
                }
                BotaoTexto {
                    visible: janela.tipo === "excluir"
                    texto: qsTr("Excluir")
                    principal: true
                    perigo: true
                    onAcionado: {
                        janela.areas.excluir(janela.area.id)
                        janela.fechar()
                    }
                }
            }
        }
    }

    onVisibleChanged: {
        if (!visible) return
        campo.text = tipo === "renomear" ? area.nome : ""
        campo.selectAll()
        // Na exclusão o foco vai para Cancelar: Enter não apaga nada sem querer.
        if (tipo === "excluir") botaoCancelar.forceActiveFocus()
        else if (tipo === "icone") caixa.forceActiveFocus()
        else campo.forceActiveFocus()
    }
}
