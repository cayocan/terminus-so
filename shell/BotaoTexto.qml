import QtQuick
import "tema"

// Botão em pílula com texto; "principal" usa o destaque do tema.
Rectangle {
    id: botao

    property string texto
    property bool principal: false
    // Ações que apagam algo para sempre.
    property bool perigo: false
    readonly property color corPrincipal: perigo ? Tema.erro : Tema.principal

    signal acionado()

    implicitWidth: rotulo.implicitWidth + 36
    implicitHeight: Tema.alvoMinimo
    radius: height / 2
    color: principal ? (toque.containsMouse ? Qt.lighter(corPrincipal, 1.1) : corPrincipal)
                     : (toque.containsMouse ? Tema.hover : "transparent")
    border.color: principal ? corPrincipal : Tema.bordaDestaque
    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: texto
    Keys.onReturnPressed: acionado()
    Keys.onSpacePressed: acionado()

    Text {
        id: rotulo
        anchors.centerIn: parent
        text: botao.texto
        color: botao.principal ? (botao.perigo ? "white" : Tema.fundo) : Tema.textoSecundario
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
