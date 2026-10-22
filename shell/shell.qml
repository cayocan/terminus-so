import QtQuick
import Quickshell
import Quickshell.Wayland

ShellRoot {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData

            screen: modelData
            anchors { top: true; bottom: true; left: true; right: true }
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.namespace: "terminus-fundo"
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"

            TelaPrincipal {
                anchors.fill: parent
            }
        }
    }
}
