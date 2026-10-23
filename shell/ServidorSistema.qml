import QtQuick
import Quickshell
import Quickshell.Io
import "tema"

// Ligação do shell com o servidor MCP do sistema (mcp/terminus_mcp): recebe pedidos de confirmação,
// comandos de tela e registros do histórico, e responde pelo mesmo socket. Reconecta sozinho se o
// servidor reiniciar.
Item {
    id: servidor

    // Telas e estado que os comandos do servidor alcançam.
    property var busca
    property var pastas
    property var configuracoes
    property var painelNotificacoes
    property var areas

    property string estadoEsfera: "repouso"
    readonly property bool conectado: socket.connected
    // Pedidos de confirmação esperando resposta, o primeiro é o que aparece: [{ id, nivel, ferramenta, cliente, resumo }]
    property var fila: []
    // Últimas ações (chegam ao vivo; o histórico completo fica no arquivo).
    property var recentes: []

    readonly property string caminhoSocket: Quickshell.env("XDG_RUNTIME_DIR") + "/terminus/interface.sock"

    function enviar(mensagem) {
        if (!socket.connected) return
        socket.write(JSON.stringify(mensagem) + "\n")
        socket.flush()
    }

    function responder(id, ok, extra) {
        enviar(Object.assign({ id: id, tipo: "resposta", ok: ok }, extra ?? {}))
        fila = fila.filter(p => p.id !== id)
    }

    function receber(linha) {
        let mensagem
        try { mensagem = JSON.parse(linha) } catch (e) { return }
        if (mensagem.tipo === "confirmar") fila = fila.concat([mensagem])
        else if (mensagem.tipo === "cancelar") fila = fila.filter(p => p.id !== mensagem.id)
        else if (mensagem.tipo === "historico") recentes = [mensagem.registro].concat(recentes).slice(0, 50)
        else if (mensagem.tipo === "comando") {
            try {
                const dados = executar(mensagem.acao, mensagem.args ?? {})
                enviar({ id: mensagem.id, tipo: "resposta", ok: true, dados: dados })
            } catch (erro) {
                enviar({ id: mensagem.id, tipo: "resposta", ok: false, erro: String(erro.message ?? erro) })
            }
        }
    }

    function expandir(caminho) {
        return caminho.startsWith("~") ? Quickshell.env("HOME") + caminho.substring(1) : caminho
    }

    // Comandos de tela pedidos pelas ferramentas do grupo "interface" e "areas". Erros viram resposta de erro.
    function executar(acao, args) {
        if (acao === "abrir") {
            if (args.tela === "busca") busca.abrir()
            else if (args.tela === "pastas") pastas.abrir(args.detalhe ? expandir(args.detalhe) : "")
            else if (args.tela === "configuracoes") configuracoes.abrir(args.detalhe ?? "")
            else if (args.tela === "notificacoes") painelNotificacoes.abrir()
            else throw new Error("tela desconhecida: " + args.tela)
            return "tela aberta"
        }
        if (acao === "esfera") {
            estadoEsfera = args.estado
            return "esfera em " + args.estado
        }
        if (acao === "preset") {
            if (!Tema.nomesPresets.includes(args.preset)) throw new Error("preset desconhecido: " + args.preset)
            configuracoes.definirPreset(args.preset)
            return "cores em " + args.preset
        }
        if (acao === "area_criar") return "área criada: " + areas.criarCom(args.nome, args.apps ?? [])
        if (acao === "area_minimizar") {
            const alvo = String(args.area).toLowerCase()
            const area = areas.lista.find(a => a.id === args.area || a.nome.toLowerCase() === alvo)
            if (!area) throw new Error("área não encontrada: " + args.area)
            areas.atualizar(area.id, { minimizada: args.minimizada !== false })
            return args.minimizada !== false ? "área minimizada" : "área aberta"
        }
        throw new Error("comando desconhecido: " + acao)
    }

    Socket {
        id: socket
        path: servidor.caminhoSocket
        connected: true
        parser: SplitParser {
            onRead: dados => servidor.receber(dados)
        }
        onConnectedChanged: if (!connected) servidor.fila = []
    }

    // O servidor pode subir depois do shell (ou reiniciar numa atualização): tenta de novo a cada 3 s.
    Timer {
        interval: 3000
        repeat: true
        running: !socket.connected
        onTriggered: {
            socket.connected = false
            socket.connected = true
        }
    }
}
