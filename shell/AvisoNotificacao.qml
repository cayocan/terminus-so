import QtQuick
import Quickshell
import Quickshell.Wayland
import "tema"

// Aviso flutuante de notificação nova no alto da tela, acima das janelas. Some sozinho depois de alguns
// segundos; clicar abre a central. Não aparece com a central aberta nem no Não perturbe (salvo urgentes).
PanelWindow {
    id: janelaAviso

    required property Notificacoes central
    required property CentralNotificacoes painel
    property var registro: null

    Connections {
        target: janelaAviso.central
        function onAviso(novo) {
            if (janelaAviso.painel.aberta) return
            janelaAviso.registro = novo
            cronometro.restart()
        }
    }

    Timer {
        id: cronometro
        interval: Tema.tempoAviso
        onTriggered: janelaAviso.registro = null
    }

    visible: registro !== null
    anchors.top: true
    margins.top: Tema.topoAviso
    implicitWidth: Tema.larguraAviso
    implicitHeight: cartao.implicitHeight
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "terminus-aviso"

    CartaoHistorico {
        id: cartao
        width: parent.width
        registro: janelaAviso.registro ?? ({ app: "", titulo: "", corpo: "", icone: "", urgente: false })
        tempo: qsTr("agora")
        aviso: true
        tamanhoIcone: Tema.iconeNotificacao
        Accessible.role: Accessible.AlertMessage

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                janelaAviso.registro = null
                janelaAviso.painel.abrir()
            }
        }
    }
}
