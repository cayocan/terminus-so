import QtQuick
import QtQuick.Layouts
import "tema"

// Um arquivo ou pasta no modo lista: ícone, nome, data de modificação e tamanho.
Rectangle {
    id: linha

    required property var entrada
    property bool selecionado: false

    // somar: Ctrl apertado, adiciona ou tira da seleção em vez de trocar.
    signal selecionar(bool somar)
    signal menuPedido(real x, real y)
    signal abrir()

    implicitHeight: Tema.alturaLinhaPasta
    radius: Tema.raioItemLateral
    color: selecionado ? Tema.itemSelecionado : (toque.containsMouse ? Qt.alpha(Tema.principal, 0.08) : "transparent")
    border.color: selecionado ? Tema.bordaSelecionado : "transparent"
    Accessible.role: Accessible.ListItem
    Accessible.name: entrada.nome
    Accessible.selected: selecionado

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 16
        spacing: 14

        Icone {
            caminhos: linha.entrada.icone
            tamanho: 22
            espessura: 1.6
            cor: linha.entrada.cor
        }
        Text {
            Layout.fillWidth: true
            elide: Text.ElideMiddle
            text: linha.entrada.nome
            color: Tema.texto
            font.family: Tema.fonteTexto
            font.pixelSize: Tema.tamanhoTextoMenor
        }
        Text {
            Layout.preferredWidth: 170
            text: linha.entrada.modificado
            color: Tema.textoDiscreto
            font.family: Tema.fonteTexto
            font.pixelSize: Tema.tamanhoRotulo
        }
        Text {
            Layout.preferredWidth: 90
            horizontalAlignment: Text.AlignRight
            text: linha.entrada.meta
            color: Tema.textoDiscreto
            font.family: Tema.fonteTexto
            font.pixelSize: Tema.tamanhoRotulo
        }
    }

    MouseArea {
        id: toque
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) linha.menuPedido(mouse.x, mouse.y)
            else linha.selecionar(mouse.modifiers & Qt.ControlModifier)
        }
        onDoubleClicked: linha.abrir()
    }
}
