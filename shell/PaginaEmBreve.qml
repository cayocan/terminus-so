import QtQuick
import QtQuick.Layouts
import "tema"

// Página de uma categoria que ainda não funciona: diz o que ela vai ter e em que fase do roadmap.
ColumnLayout {
    id: pagina

    property string titulo
    property string fase
    property var itens: []

    spacing: 26

    TituloPagina {
        Layout.fillWidth: true
        titulo: pagina.titulo
        descricao: qsTr("Esta parte ainda está sendo construída (%1). Ela vai ter:").arg(pagina.fase)
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 12
        Repeater {
            model: pagina.itens
            delegate: RowLayout {
                required property string modelData
                Layout.fillWidth: true
                spacing: 12
                Rectangle {
                    Layout.preferredWidth: 6
                    Layout.preferredHeight: 6
                    Layout.alignment: Qt.AlignTop
                    Layout.topMargin: 8
                    radius: 3
                    color: Tema.principal
                }
                Text {
                    Layout.fillWidth: true
                    text: modelData
                    wrapMode: Text.Wrap
                    color: Tema.textoSecundario
                    font.family: Tema.fonteTexto
                    font.pixelSize: Tema.tamanhoTexto
                }
            }
        }
    }
}
