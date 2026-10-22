import QtQuick

Rectangle {
    id: tela

    property string estadoAssistente: "repouso"

    color: "#04070D"

    Esfera {
        id: esfera
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -60
        width: Math.min(tela.width, tela.height) * 0.48
        height: width
        estado: tela.estadoAssistente
    }

    Text {
        anchors.top: esfera.bottom
        anchors.topMargin: 16
        anchors.horizontalCenter: parent.horizontalCenter
        text: qsTr("Em repouso")
        color: "#B8D2E2"
        font.family: "Inter"
        font.pixelSize: 18
    }
}
