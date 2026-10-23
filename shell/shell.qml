import QtQuick
import Quickshell
import Quickshell.Wayland

ShellRoot {
    Notificacoes {
        id: centralNotificacoes
    }

    Areas {
        id: areasAtalho
    }

    Pastas {
        id: navegadorPastas
        areas: areasAtalho
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
                areas: areasAtalho
                mostrarAreas: modelData === Quickshell.screens[0]
                tamanhoTela: Qt.size(modelData.width, modelData.height)
            }
        }
    }

    Variants {
        model: Quickshell.screens

        Dock {
            required property var modelData
            screen: modelData
            pastas: navegadorPastas
            busca: buscaGlobal
        }
    }

    Busca {
        id: buscaGlobal
        pastas: navegadorPastas
        screen: Quickshell.screens[0]
    }

    Dialogos {
        areas: areasAtalho
        screen: Quickshell.screens[0]
    }
}
