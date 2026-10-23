import QtQuick
import "tema"

// Um arquivo ou pasta no modo ícones. Clique seleciona, clique duplo abre.
Rectangle {
    id: item

    // { nome, caminho, pasta, icone, cor, fundoIcone, meta }
    required property var entrada
    property bool selecionado: false

    // somar: Ctrl apertado, adiciona ou tira da seleção em vez de trocar.
    signal selecionar(bool somar)
    signal menuPedido(real x, real y)
    signal abrir()

    radius: Tema.raioItemPasta
    color: selecionado ? Tema.itemSelecionado : (toque.containsMouse ? Qt.alpha(Tema.principal, 0.08) : "transparent")
    border.color: selecionado ? Tema.bordaSelecionado : "transparent"
    Accessible.role: Accessible.ListItem
    Accessible.name: entrada.nome
    Accessible.description: entrada.meta
    Accessible.selected: selecionado

    Column {
        anchors.centerIn: parent
        width: parent.width - 20
        spacing: 10

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 64
            height: 56
            radius: Tema.raioIconeItemPasta
            color: item.entrada.fundoIcone
            Icone {
                anchors.centerIn: parent
                caminhos: item.entrada.icone
                tamanho: 34
                espessura: 1.5
                cor: item.entrada.cor
            }
        }
        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: item.entrada.nome
            wrapMode: Text.WrapAnywhere
            maximumLineCount: 2
            elide: Text.ElideRight
            lineHeight: 1.3
            color: Tema.texto
            font.family: Tema.fonteTexto
            font.pixelSize: Tema.tamanhoTextoMenor
        }
        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: item.entrada.meta
            color: Tema.textoDiscreto
            font.family: Tema.fonteTexto
            font.pixelSize: Tema.tamanhoLegenda
        }
    }

    MouseArea {
        id: toque
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) item.menuPedido(mouse.x, mouse.y)
            else item.selecionar(mouse.modifiers & Qt.ControlModifier)
        }
        onDoubleClicked: item.abrir()
    }
}
