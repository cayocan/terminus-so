pragma Singleton
import QtQuick

// Ícone e cores de cada tipo de arquivo, iguais no navegador de pastas e na pasta em leque da dock.
QtObject {
    function tipo(sufixo, pasta) {
        if (pasta) return { icone: Icones.pasta, cor: Tema.corPasta, fundo: Tema.pastaSuave }
        const s = (sufixo ?? "").toLowerCase()
        const destaque = icone => ({ icone: icone, cor: Tema.principal, fundo: Tema.destaqueSuave })
        const neutro = icone => ({ icone: icone, cor: Tema.textoTerciario, fundo: Tema.superficieNeutra })
        if (["png", "jpg", "jpeg", "gif", "webp", "svg", "bmp"].includes(s)) return destaque(Icones.imagem)
        if (["ogg", "mp3", "flac", "wav", "opus", "m4a"].includes(s)) return destaque(Icones.audio)
        if (["mp4", "mkv", "webm", "avi", "mov"].includes(s)) return destaque(Icones.video)
        if (["zip", "tar", "gz", "xz", "zst", "7z", "rar"].includes(s)) return neutro(Icones.compactado)
        if (["deb", "appimage", "flatpakref"].includes(s)) return { icone: Icones.pacote, cor: Tema.corPasta, fundo: Tema.pastaSuave }
        return neutro(Icones.documento)
    }
}
