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
        servidor: servidorSistema
    }

    // Ligação com o servidor MCP do sistema (confirmações, comandos de tela, histórico).
    ServidorSistema {
        id: servidorSistema
        busca: buscaGlobal
        pastas: navegadorPastas
        configuracoes: preferencias
        painelNotificacoes: centralPainel
        areas: areasAtalho
    }

    // Assistente local (modelo no llama.cpp agindo pelo servidor do sistema).
    Assistente {
        id: assistenteLocal
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
                estadoAssistente: servidorSistema.estadoEsfera
                esferaAssistente: assistenteLocal.esfera
                respostaAssistente: assistenteLocal.resposta
                onConversaPedida: conversaAssistente.abrir()
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

    PerguntaAssistente {
        id: conversaAssistente
        assistente: assistenteLocal
        nomeAssistente: preferencias.nomeAssistente
        cederTeclado: servidorSistema.fila.length > 0
        screen: Quickshell.screens[0]
    }

    ConfirmacaoAcao {
        servidor: servidorSistema
        screen: Quickshell.screens[0]
    }

    Dialogos {
        areas: areasAtalho
        screen: Quickshell.screens[0]
    }
}
