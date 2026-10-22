import QtQuick
import "tema"

// Um ícone da dock, com efeito de lupa ao passar o mouse e um ponto embaixo quando o app está aberto.
Column {
    id: item

    property string nome
    property var icone: []
    property bool aberto: false
    property bool disponivel: true
    // Atalhos de pastas e lixeira têm fundo neutro em vez do destaque.
    property bool neutro: false

    signal acionado()

    spacing: 6
    z: toque.containsMouse ? 1 : 0

    Rectangle {
        id: botao
        width: Tema.dockIcone
        height: Tema.dockIcone
        radius: Tema.raioItemDock
        color: item.neutro ? Tema.superficieNeutra : Tema.destaqueSuave
        border.color: item.activeFocus ? Tema.principal : Tema.bordaDestaque
        opacity: item.disponivel ? 1 : 0.45
        scale: toque.containsMouse && item.disponivel ? Tema.dockLupa : 1
        transformOrigin: Item.Bottom
        transform: Translate { y: toque.containsMouse && item.disponivel ? -Tema.dockLupaSubida : 0 }

        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        Icone {
            anchors.centerIn: parent
            caminhos: item.icone
            tamanho: 28
            cor: item.neutro ? Tema.textoSecundario : Tema.principal
        }

        MouseArea {
            id: toque
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: item.disponivel ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: if (item.disponivel) item.acionado()
        }
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        width: Tema.dockIndicador
        height: Tema.dockIndicador
        radius: width / 2
        color: item.aberto ? Tema.principal : "transparent"
    }

    activeFocusOnTab: item.disponivel
    Keys.onReturnPressed: item.acionado()
    Keys.onSpacePressed: item.acionado()
    Accessible.role: Accessible.Button
    Accessible.name: nome
    Accessible.description: !disponivel ? qsTr("Em breve") : (aberto ? qsTr("Aberto") : "")
}
