import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import "tema"

// Servidor de notificações do sistema (org.freedesktop.Notifications). Uma instância só, no shell.qml.
// Guarda a hora de chegada (o protocolo não informa) e um histórico de 7 dias em ~/.local/state/terminus,
// que alimenta a central e o "O que eu perdi?".
Item {
    id: central

    property bool naoPerturbe: false
    // Notificações vivas, mais recentes primeiro: [{ notificacao, chegada }]
    property var lista: []
    // Histórico, mais recentes primeiro: [{ id, app, titulo, corpo, icone, urgente, chegada (ms), lida }]
    property var historico: []
    // Resumo do "O que eu perdi?" sendo mostrado na tela principal: { texto, vazio } ou null.
    property var resumo: null

    readonly property int naoLidas: historico.filter(h => !h.lida).length
    readonly property int diasGuardados: 7
    readonly property int maximoGuardado: 200

    // Uma notificação nova para o aviso flutuante (não chega durante o Não perturbe, salvo as urgentes).
    signal aviso(var registro)

    function remover(notificacao) {
        lista = lista.filter(r => r.notificacao !== notificacao)
    }

    function salvar() {
        arquivo.setText(JSON.stringify({ versao: 1, historico: historico }))
    }

    function limpar(ids) {
        historico = historico.filter(h => !ids.includes(h.id))
        // As notificações vivas que foram limpas somem também do widget.
        for (const r of lista)
            if (ids.includes(r.id)) r.notificacao.dismiss()
        salvar()
    }

    function marcarLidas() {
        if (naoLidas === 0) return
        historico = historico.map(h => h.lida ? h : Object.assign({}, h, { lida: true }))
        salvar()
    }

    // O resumo é texto formatado; nomes vindos dos apps não podem virar marcação.
    function escapar(texto) {
        return (texto ?? "").replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
    }

    // Resumo em texto do que chegou sem ser visto. A voz (Piper) entra quando o assistente existir.
    function oQueEuPerdi() {
        const novas = historico.filter(h => !h.lida)
        if (novas.length === 0) {
            resumo = { vazio: true, texto: qsTr("Você não perdeu nada. Nenhuma notificação nova desde a última vez.") }
        } else {
            const porApp = {}
            for (const h of novas) porApp[h.app] = (porApp[h.app] ?? 0) + 1
            const partes = Object.keys(porApp).sort((a, b) => porApp[b] - porApp[a])
                .map(app => qsTr("%1 (%2)").arg(escapar(app)).arg(porApp[app]))
            const relacao = partes.length === 1 ? partes[0]
                        : partes.slice(0, -1).join(", ") + qsTr(" e ") + partes[partes.length - 1]
            const destaque = n => "<font color='" + Tema.principalClaro + "'><b>" + n + "</b></font>"
            let texto = novas.length === 1
                ? qsTr("Enquanto você estava fora, chegou %1: %2.").arg(destaque(qsTr("1 notificação"))).arg(relacao)
                : qsTr("Enquanto você estava fora, chegaram %1: %2.").arg(destaque(qsTr("%1 notificações").arg(novas.length))).arg(relacao)
            const urgentes = novas.filter(h => h.urgente)
            if (urgentes.length === 1) texto += " " + qsTr("Uma é urgente: “%1”.").arg(escapar(urgentes[0].titulo || urgentes[0].app))
            else if (urgentes.length > 1) texto += " " + qsTr("%1 são urgentes.").arg(urgentes.length)
            resumo = { vazio: false, texto: texto }
        }
        marcarLidas()
        fimResumo.restart()
    }

    Timer {
        id: fimResumo
        interval: 20000
        onTriggered: central.resumo = null
    }

    FileView {
        id: arquivo
        path: Quickshell.env("HOME") + "/.local/state/terminus/notificacoes.json"
        blockLoading: true
        printErrors: false
        onLoaded: {
            try {
                const limite = Date.now() - central.diasGuardados * 86400000
                central.historico = (JSON.parse(text()).historico ?? []).filter(h => h.chegada >= limite)
            } catch (e) {
                console.warn("notificacoes.json inválido, começando um histórico novo:", e)
            }
        }
    }

    NotificationServer {
        keepOnReload: false
        bodySupported: true
        imageSupported: true
        actionsSupported: false

        onNotification: notificacao => {
            notificacao.tracked = true
            notificacao.closed.connect(() => central.remover(notificacao))
            const chegada = new Date()
            const id = chegada.getTime() + "-" + notificacao.id
            const registro = {
                id: id, app: notificacao.appName || qsTr("Sistema"),
                titulo: notificacao.summary, corpo: notificacao.body, icone: notificacao.appIcon,
                urgente: notificacao.urgency === NotificationUrgency.Critical,
                chegada: chegada.getTime(), lida: false
            }
            central.lista = [{ notificacao: notificacao, chegada: chegada, id: id }].concat(central.lista)
            central.historico = [registro].concat(central.historico).slice(0, central.maximoGuardado)
            central.salvar()
            if (!central.naoPerturbe || registro.urgente) central.aviso(registro)
        }
    }
}
