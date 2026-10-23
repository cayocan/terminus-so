import QtQuick
import "tema"

// Botão em pílula com texto; "principal" usa o destaque do tema.
Rectangle {
    id: botao

    property string texto
    property bool principal: false

    signal acionado()

    implicitWidth: rotulo.implicitWidth + 36
    implicitHeight: Tema.alvoMinimo
    radius: height / 2
    color: principal ? (toque.containsMouse ? Qt.lighter(Tema.principal, 1.1) : Tema.principal)
                     : (toque.containsMouse ? Tema.hover : "transparent")
    border.color: principal ? Tema.principal : Tema.bordaDestaque
    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: texto
    Keys.onReturnPressed: acionado()
    Keys.onSpacePressed: acionado()

    Text {
        id: rotulo
        anchors.centerIn: parent
        text: botao.texto
        color: botao.principal ? Tema.fundo : Tema.textoSecundario
        font.family: Tema.fonteTexto
        font.weight: botao.principal ? Font.DemiBold : Font.Normal
        font.pixelSize: Tema.tamanhoTextoMenor
    }

    MouseArea {
        id: toque
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: botao.acionado()
    }
}
