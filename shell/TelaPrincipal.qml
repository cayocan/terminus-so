import QtQuick
import "tema"

Rectangle {
    id: tela

    property string estadoAssistente: "repouso"

    color: Tema.fundo

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
        anchors.topMargin: Tema.espaco
        anchors.horizontalCenter: parent.horizontalCenter
        text: qsTr("Em repouso")
        color: Tema.textoSecundario
        font.family: Tema.fonteTexto
        font.pixelSize: Tema.tamanhoTextoGrande
    }
}
