import QtQuick
import Quickshell
import Quickshell.Io

// Operações de arquivo do navegador de pastas, uma de cada vez, com os comandos do sistema
// (cp, mv, mkdir) e a lixeira padrão do freedesktop pelo gio (que guarda de onde o arquivo veio).
Item {
    id: operacoes

    property var fila: []
    property var erros: []
    readonly property bool ocupado: processo.running || fila.length > 0

    // Terminou o lote: erros é uma lista de mensagens (vazia se deu tudo certo).
    signal concluido(var erros)

    function nomeDe(caminho) { return caminho.substring(caminho.lastIndexOf("/") + 1) }

    // "foto.png" já existe? Vira "foto (cópia).png", depois "foto (cópia 2).png"...
    function nomeLivre(nome, existentes, pasta) {
        if (!existentes.includes(nome)) return nome
        const ponto = pasta ? -1 : nome.lastIndexOf(".")
        const base = ponto > 0 ? nome.substring(0, ponto) : nome
        const extensao = ponto > 0 ? nome.substring(ponto) : ""
        for (let n = 1; ; n++) {
            const candidato = base + (n === 1 ? qsTr(" (cópia)") : qsTr(" (cópia %1)").arg(n)) + extensao
            if (!existentes.includes(candidato)) return candidato
        }
    }

    function enfileirar(comandos) {
        fila = fila.concat(comandos)
        if (!processo.running) proximo()
    }

    function proximo() {
        if (fila.length === 0) {
            const lote = erros
            erros = []
            concluido(lote)
            return
        }
        processo.command = fila[0]
        fila = fila.slice(1)
        processo.running = true
    }

    // itens: [{ caminho, pasta }]; existentes: nomes que já estão no destino.
    function colar(itens, destino, recortar, existentes) {
        const ocupados = existentes.slice()
        const comandos = []
        for (const item of itens) {
            // Recortar e colar na mesma pasta não muda nada.
            if (recortar && item.caminho.substring(0, item.caminho.lastIndexOf("/")) === destino) continue
            const nome = nomeLivre(nomeDe(item.caminho), ocupados, item.pasta)
            ocupados.push(nome)
            comandos.push(recortar ? ["mv", "-n", "--", item.caminho, destino + "/" + nome]
                                   : ["cp", "-r", "--", item.caminho, destino + "/" + nome])
        }
        enfileirar(comandos)
    }

    function renomear(caminho, novoNome) {
        enfileirar([["mv", "-n", "--", caminho, caminho.substring(0, caminho.lastIndexOf("/") + 1) + novoNome]])
    }

    function novaPasta(destino, nome) {
        enfileirar([["mkdir", "--", destino + "/" + nome]])
    }

    function moverParaLixeira(caminhos) {
        enfileirar([["gio", "trash", "--"].concat(caminhos)])
    }

    // Restaurar e esvaziar seguem o padrão freedesktop direto nos arquivos: o "gio trash --restore" e o
    // "--empty" usam o endereço trash:///, que precisa do gvfs (não vem na ISO). O "gio trash" de mandar
    // para a lixeira funciona sem ele.
    // $1 = arquivo na lixeira, $2 = caminho original, $3 = registro .trashinfo
    readonly property string scriptRestaurar: `
        [ -e "$2" ] && { echo "Já existe um item em $2" >&2; exit 1; }
        mkdir -p -- "$(dirname -- "$2")" && mv -n -- "$1" "$2" && rm -f -- "$3"
    `
    readonly property string scriptEsvaziar: `
        lixeira="$HOME/.local/share/Trash"
        find "$lixeira/files" "$lixeira/info" -mindepth 1 -delete
    `

    // Na lixeira, o nome do arquivo é o identificador; o caminho original fica em info/<nome>.trashinfo,
    // codificado como URL (%C3%A7 para "ç"), e é decodificado aqui para não depender de escapes no shell.
    function restaurar(nomes) {
        const lixeira = Quickshell.env("HOME") + "/.local/share/Trash"
        const comandos = []
        for (const nome of nomes) {
            const info = lixeira + "/info/" + nome + ".trashinfo"
            registro.path = info
            registro.reload()
            const linha = registro.text().split("\n").find(l => l.startsWith("Path="))
            if (!linha) {
                erros = erros.concat([qsTr("Não há registro de onde “%1” veio.").arg(nome)])
                continue
            }
            const destino = decodeURIComponent(linha.substring(5).trim())
            comandos.push(["sh", "-c", scriptRestaurar, "sh", lixeira + "/files/" + nome, destino, info])
        }
        enfileirar(comandos)
    }

    function esvaziarLixeira() {
        enfileirar([["sh", "-c", scriptEsvaziar]])
    }

    FileView {
        id: registro
        // Começa apontando para a pasta de registros: trocar a partir de um caminho vazio gera aviso do Qt.
        path: Quickshell.env("HOME") + "/.local/share/Trash/info"
        blockLoading: true
        printErrors: false
    }

    Process {
        id: processo
        stderr: StdioCollector { id: saidaErro }
        onExited: codigo => {
            if (codigo !== 0) {
                const mensagem = saidaErro.text.trim()
                operacoes.erros = operacoes.erros.concat([mensagem !== "" ? mensagem : qsTr("Falha em %1").arg(command[0])])
            }
            operacoes.proximo()
        }
    }
}
