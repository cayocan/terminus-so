import QtQuick
import "tema"

// Botão quadrado só com ícone (44×44), como os de redimensionar e minimizar das áreas.
Rectangle {
    id: botao

    property string nome
    property var icone: []
    property bool marcado: false

    signal acionado()

    implicitWidth: Tema.alvoMinimo
    implicitHeight: Tema.alvoMinimo
    radius: Tema.raioBotaoArea
    color: marcado ? Tema.selecaoFundo : (toque.containsMouse ? Tema.hover : "transparent")
    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: nome
    Keys.onReturnPressed: acionado()
    Keys.onSpacePressed: acionado()

    Icone {
        anchors.centerIn: parent
        caminhos: botao.icone
        tamanho: 18
        espessura: 1.8
        cor: botao.marcado ? Tema.principal : Tema.textoDiscreto
    }

    MouseArea {
        id: toque
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: botao.acionado()
    }
}
