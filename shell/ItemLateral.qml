import QtQuick
import QtQuick.Layouts
import "tema"

// Um item da barra lateral do navegador de pastas: ícone (ou ponto colorido), nome e nota à direita.
Rectangle {
    id: item

    property string nome
    property var icone: []
    property color corPonto: "transparent"
    property string nota
    property bool ativo: false

    signal acionado()

    implicitHeight: Tema.alturaItemLateral
    radius: Tema.raioItemLateral
    color: ativo ? Tema.destaqueSuave : (toque.containsMouse ? Qt.rgba(1, 1, 1, 0.05) : "transparent")
    Accessible.role: Accessible.Link
    Accessible.name: nome

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 12

        Icone {
            visible: item.icone.length > 0
            caminhos: item.icone
            tamanho: 17
            espessura: 1.8
            cor: item.ativo ? Tema.texto : Tema.textoSecundario
        }
        Rectangle {
            visible: item.icone.length === 0
            Layout.preferredWidth: 10
            Layout.preferredHeight: 10
            radius: 5
            color: item.corPonto
        }
        Text {
            Layout.fillWidth: true
            elide: Text.ElideRight
            text: item.nome
            color: item.ativo ? Tema.texto : Tema.textoSecundario
            font.family: Tema.fonteTexto
            font.pixelSize: Tema.tamanhoTextoMenor
        }
        Text {
            visible: item.nota !== ""
            text: item.nota
            color: Tema.textoDiscreto
            font.family: Tema.fonteTexto
            font.pixelSize: Tema.tamanhoLegenda
        }
    }

    MouseArea {
        id: toque
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: item.acionado()
    }
}
