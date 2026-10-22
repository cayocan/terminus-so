import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../shell"
import "../shell/tema"

ApplicationWindow {
    width: 900
    height: 760
    visible: true
    title: qsTr("Terminus SO — prévia da esfera")
    color: Tema.fundo

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: Tema.espaco

        Esfera {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 520
            Layout.preferredHeight: 520
            estado: seletorEstado.currentText
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 12

            Label { text: qsTr("Estado"); color: Tema.textoTerciario }
            ComboBox {
                id: seletorEstado
                model: ["repouso", "escutando", "pensando", "falando", "programando", "atencao", "erro"]
            }
            Label { text: qsTr("Preset"); color: Tema.textoTerciario }
            ComboBox {
                model: Tema.nomesPresets
                onActivated: Tema.preset = currentText
            }
        }
    }
}
