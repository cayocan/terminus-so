import QtQuick
import Quickshell
import Quickshell.Wayland

ShellRoot {
    Notificacoes {
        id: centralNotificacoes
    }

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
                notificacoes: centralNotificacoes
            }
        }
    }

    Variants {
        model: Quickshell.screens

        Dock {
            required property var modelData
            screen: modelData
        }
    }
}
