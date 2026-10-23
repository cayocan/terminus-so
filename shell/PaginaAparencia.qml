import QtQuick
import QtQuick.Layouts
import "tema"

// Página Aparência e cores: escolha do preset (Jarvis clássico, Mark, Stealth). Muda o sistema todo na hora.
ColumnLayout {
    id: pagina

    required property var configuracoes

    spacing: 26

    TituloPagina {
        Layout.fillWidth: true
        titulo: qsTr("Aparência e cores")
        descricao: qsTr("A cor da esfera e dos destaques de todo o sistema. Cores livres chegam numa próxima versão.")
    }

    Flow {
        Layout.fillWidth: true
        spacing: 18

        Repeater {
            model: Tema.nomesPresets
            delegate: Rectangle {
                id: opcao
                required property string modelData
                readonly property bool escolhido: Tema.preset === modelData
                readonly property var cores: Tema.presets[modelData]

                width: Tema.larguraMinimaCartao
                height: 150
                radius: Tema.raioCartaoConector
                color: escolhido ? Tema.selecaoFundo : (toque.containsMouse ? Qt.tint(Tema.fundoCartaoConector, Tema.hover) : Tema.fundoCartaoConector)
                border.color: escolhido ? Tema.principal : Tema.bordaNeutra
                border.width: escolhido ? 2 : 1
                activeFocusOnTab: true
                Accessible.role: Accessible.RadioButton
                Accessible.name: modelData
                Accessible.checked: escolhido
                Keys.onSpacePressed: pagina.configuracoes.definirPreset(modelData)

                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: 22
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 16
                    Row {
                        spacing: -12
                        Rectangle { width: 48; height: 48; radius: 24; color: opcao.cores.principal }
                        Rectangle { width: 48; height: 48; radius: 24; color: opcao.cores.profunda; border.color: Tema.fundo; border.width: 3 }
                    }
                    Text {
                        text: opcao.modelData
                        color: Tema.texto
                        font.family: Tema.fonteTexto
                        font.weight: Font.DemiBold
                        font.pixelSize: Tema.tamanhoNomeConector
                    }
                }
                Text {
                    visible: opcao.escolhido
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 18
                    text: qsTr("Em uso")
                    color: Tema.principalClaro
                    font.family: Tema.fonteTexto
                    font.weight: Font.DemiBold
                    font.pixelSize: Tema.tamanhoRotulo
                }
                MouseArea {
                    id: toque
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: pagina.configuracoes.definirPreset(opcao.modelData)
                }
            }
        }
    }
}
