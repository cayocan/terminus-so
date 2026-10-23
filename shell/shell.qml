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

    Configuracoes {
        id: preferencias
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
                painelNotificacoes: centralPainel
                nomeAssistente: preferencias.nomeAssistente
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
            configuracoes: preferencias
        }
    }

    CentralNotificacoes {
        id: centralPainel
        central: centralNotificacoes
        screen: Quickshell.screens[0]
    }

    AvisoNotificacao {
        central: centralNotificacoes
        painel: centralPainel
        screen: Quickshell.screens[0]
    }

    Busca {
        id: buscaGlobal
        pastas: navegadorPastas
        configuracoes: preferencias
        screen: Quickshell.screens[0]
    }

    Dialogos {
        areas: areasAtalho
        screen: Quickshell.screens[0]
    }
}
