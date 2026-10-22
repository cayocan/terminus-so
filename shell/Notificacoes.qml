import QtQuick
import Quickshell.Services.Notifications

// Servidor de notificações do sistema (org.freedesktop.Notifications). Uma instância só, no shell.qml.
// Guarda a hora de chegada de cada notificação, que o protocolo não informa.
Item {
    id: central

    property bool naoPerturbe: false
    // Mais recentes primeiro: [{ notificacao, chegada }]
    property var lista: []

    function remover(notificacao) {
        lista = lista.filter(r => r.notificacao !== notificacao)
    }

    NotificationServer {
        keepOnReload: false
        bodySupported: true
        imageSupported: true
        actionsSupported: false

        onNotification: notificacao => {
            notificacao.tracked = true
            notificacao.closed.connect(() => central.remover(notificacao))
            central.lista = [{ notificacao: notificacao, chegada: new Date() }].concat(central.lista)
        }
    }
}
