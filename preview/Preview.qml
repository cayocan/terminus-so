import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../shell"

ApplicationWindow {
    id: janela

    readonly property var presets: ({
        "Jarvis clássico": ["#22D3EE", "#1E6BFF"],
        "Mark": ["#F5B83D", "#E5484D"],
        "Stealth": ["#D6DEE6", "#6B7A8C"]
    })

    width: 900
    height: 760
    visible: true
    title: qsTr("Terminus SO — prévia da esfera")
    color: "#04070D"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 16

        Esfera {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 520
            Layout.preferredHeight: 520
            estado: seletorEstado.currentText
            corPrincipal: janela.presets[seletorPreset.currentText][0]
            corProfunda: janela.presets[seletorPreset.currentText][1]
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 12

            Label { text: qsTr("Estado"); color: "#A9C7DA" }
            ComboBox {
                id: seletorEstado
                model: ["repouso", "escutando", "pensando", "falando", "programando", "atencao", "erro"]
            }
            Label { text: qsTr("Preset"); color: "#A9C7DA" }
            ComboBox {
                id: seletorPreset
                model: ["Jarvis clássico", "Mark", "Stealth"]
            }
        }
    }
}
