import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Controle do navegador de pastas: uma janela só, criada no primeiro uso. Abrir de novo (pela dock)
// mostra a janela, que pode estar minimizada, e navega até a pasta pedida.
Item {
    id: controle

    property Areas areas
    readonly property bool aberta: carregador.active
    readonly property string inicio: Quickshell.env("HOME")
    // Lixeira padrão do freedesktop (a mesma que o gio usa).
    readonly property string lixeira: inicio + "/.local/share/Trash/files"
    // Copiar/recortar vale entre navegações: { recortar: bool, itens: [{ caminho, pasta }] }
    property var areaTransferencia: null

    // Pastas do usuário lidas de ~/.config/user-dirs.dirs (nomes já traduzidos pelo xdg-user-dirs).
    property var pastasUsuario: ({
        DOCUMENTS: inicio + "/Documentos", DOWNLOAD: inicio + "/Downloads",
        PICTURES: inicio + "/Imagens", MUSIC: inicio + "/Música", VIDEOS: inicio + "/Vídeos"
    })

    function abrir(caminho) {
        const destino = caminho || inicio
        if (!carregador.active) {
            carregador.caminhoInicial = destino
            carregador.active = true
            return
        }
        const janela = carregador.item
        if (caminho) janela.navegar(caminho)
        janela.visible = true
        Hyprland.dispatch("focuswindow title:.* — Pastas$")
    }

    function fechar() { carregador.active = false }

    // A pasta da lixeira precisa existir: com uma pasta inexistente, a lista mostraria outra no lugar.
    Process {
        running: true
        command: ["mkdir", "-p", controle.lixeira]
    }

    FileView {
        path: controle.inicio + "/.config/user-dirs.dirs"
        printErrors: false
        onLoaded: {
            const lidas = Object.assign({}, controle.pastasUsuario)
            for (const linha of text().split("\n")) {
                const m = linha.match(/^XDG_(\w+)_DIR="(.*)"$/)
                if (m) lidas[m[1]] = m[2].replace("$HOME", controle.inicio)
            }
            controle.pastasUsuario = lidas
        }
    }

    LazyLoader {
        id: carregador
        property string caminhoInicial

        JanelaPastas {
            pastas: controle
            caminhoInicial: carregador.caminhoInicial
        }
    }
}
