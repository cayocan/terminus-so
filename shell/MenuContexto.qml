import QtQuick
import "tema"

// Menu de clique direito da tela principal. Cobre a tela com uma camada invisível que fecha o menu
// ao clicar fora. Itens: [{ texto, acao: function, perigo?: bool }]
Item {
    id: menu

    property var itens: []
    property point posicao

    function abrir(x, y, novosItens) {
        itens = novosItens
        posicao = Qt.point(x, y)
        visible = true
    }
    function fechar() { visible = false }

    visible: false
    z: 100

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onPressed: menu.fechar()
    }

    Rectangle {
        id: caixa
        x: Math.min(menu.posicao.x, menu.width - width - 8)
        y: Math.min(menu.posicao.y, menu.height - height - 8)
        width: Tema.larguraMenu
        height: lista.implicitHeight + 12
        radius: Tema.raioMenu
        color: Tema.vidroJanela
        border.color: Tema.bordaDestaque
        Accessible.role: Accessible.PopupMenu

        Column {
            id: lista
            anchors.fill: parent
            anchors.margins: 6

            Repeater {
                model: menu.itens
                delegate: Rectangle {
                    required property var modelData
                    width: lista.width
                    height: Tema.alturaItemMenu
                    radius: Tema.raioBotaoArea - 2
                    color: toqueItem.containsMouse ? Tema.hover : "transparent"
                    Accessible.role: Accessible.MenuItem
                    Accessible.name: modelData.texto

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        text: modelData.texto
                        color: modelData.perigo ? Tema.erroTexto : Tema.texto
                        font.family: Tema.fonteTexto
                        font.pixelSize: Tema.tamanhoTextoMenor
                    }
                    MouseArea {
                        id: toqueItem
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            menu.fechar()
                            modelData.acao()
                        }
                    }
                }
            }
        }
    }
}
