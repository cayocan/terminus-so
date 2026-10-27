import QtQuick
import Quickshell
import Quickshell.Io

// Ligação do shell com o assistente local (assistente/terminus_assistente): manda perguntas (digitadas ou
// faladas), recebe o estado da esfera, do modelo (baixando, carregando, pronto), da voz e as respostas.
// Reconecta sozinho se o serviço reiniciar.
Item {
    id: assistente

    readonly property bool conectado: socket.connected
    property string esfera: "repouso"
    // { id, nome, tamanho, estado: ausente|baixando|carregando|pronto|erro|verificando, progresso, erro }
    property var modelo: ({ estado: "verificando" })
    // Última resposta: { pergunta, texto, acoes, semModelo }; some sozinha depois de um tempo na tela principal.
    property var resposta: null
    property string perguntaPendente: ""
    property string agindo: ""
    // { pronta, falar, ouvindo, baixando, erro }: pronta quando a voz e o ouvido foram baixados e subiram.
    property var voz: ({ pronta: false, falar: true, ouvindo: false, baixando: false, erro: "" })
    // Aviso curto sobre a última escuta ("Não ouvi nada"), some na próxima pergunta.
    property string avisoVoz: ""

    readonly property string caminhoSocket: Quickshell.env("XDG_RUNTIME_DIR") + "/terminus/assistente.sock"

    function enviar(mensagem) {
        if (!socket.connected) return false
        socket.write(JSON.stringify(mensagem) + "\n")
        socket.flush()
        return true
    }
    function perguntar(texto) {
        texto = texto.trim()
        if (texto === "") return
        if (!enviar({ tipo: "perguntar", texto: texto })) {
            resposta = { pergunta: texto, texto: qsTr("O assistente não está rodando."), acoes: [] }
            return
        }
        perguntaPendente = texto
        resposta = null
        agindo = ""
        avisoVoz = ""
    }
    function baixar() { enviar({ tipo: "baixar" }) }
    function ouvir() {
        avisoVoz = ""
        enviar({ tipo: "ouvir" })
    }
    function pararOuvir() { enviar({ tipo: "parar_ouvir" }) }
    function cancelarOuvir() { if (voz.ouvindo) enviar({ tipo: "cancelar_ouvir" }) }
    function calar() { enviar({ tipo: "calar" }) }
    function definirFalar(ligado) { enviar({ tipo: "falar", ligado: ligado }) }
    function cancelarDownload() { enviar({ tipo: "cancelar_download" }) }

    function receber(linha) {
        let mensagem
        try { mensagem = JSON.parse(linha) } catch (e) { return }
        if (mensagem.tipo === "estado") {
            esfera = mensagem.esfera
            modelo = mensagem.modelo
            if (mensagem.voz) voz = mensagem.voz
        } else if (mensagem.tipo === "ouvido") {
            if (mensagem.texto) {
                perguntaPendente = mensagem.texto
                resposta = null
                agindo = ""
            } else {
                avisoVoz = mensagem.erro ? qsTr("Não consegui ouvir: %1").arg(mensagem.erro) : qsTr("Não ouvi nada.")
            }
        } else if (mensagem.tipo === "agindo") {
            agindo = mensagem.ferramenta
        } else if (mensagem.tipo === "resposta") {
            if (mensagem.pergunta === perguntaPendente) perguntaPendente = ""
            agindo = ""
            resposta = mensagem
            limpar.restart()
        }
    }

    // A resposta fica na tela pelo tempo de leitura (mínimo de 12 s).
    Timer {
        id: limpar
        interval: Math.max(12000, (assistente.resposta?.texto?.length ?? 0) * 90)
        onTriggered: assistente.resposta = null
    }

    Socket {
        id: socket
        path: assistente.caminhoSocket
        connected: true
        parser: SplitParser {
            onRead: dados => assistente.receber(dados)
        }
        onConnectedChanged: if (!connected) {
            assistente.esfera = "repouso"
            assistente.perguntaPendente = ""
        }
    }

    // O serviço pode subir depois do shell (ou reiniciar): tenta de novo a cada 3 s.
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
