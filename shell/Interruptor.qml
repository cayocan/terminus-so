import QtQuick
import "tema"

// Interruptor liga/desliga. Só desenha; quem usa decide o que o clique faz (alternado()).
Rectangle {
    id: interruptor

    property bool ligado: false
    property bool ativo: true

    signal alternado()

    implicitWidth: Tema.larguraInterruptor
    implicitHeight: Tema.alturaInterruptor
    radius: height / 2
    color: ligado ? Tema.principal : Tema.trilhoBarra
    opacity: ativo ? 1 : 0.45
    activeFocusOnTab: ativo
    Accessible.role: Accessible.CheckBox
    Accessible.checked: ligado
    Keys.onSpacePressed: if (ativo) alternado()

    Rectangle {
        width: interruptor.height - 6
        height: width
        radius: width / 2
        anchors.verticalCenter: parent.verticalCenter
        x: interruptor.ligado ? parent.width - width - 3 : 3
        color: interruptor.ligado ? Tema.fundo : Tema.textoSecundario
        Behavior on x { NumberAnimation { duration: 150 } }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -10
        enabled: interruptor.ativo
        cursorShape: Qt.PointingHandCursor
        onClicked: interruptor.alternado()
    }
}
