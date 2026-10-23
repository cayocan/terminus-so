pragma Singleton
import QtQuick

// Ícones de traço do design (docs/design/telas/*.dc.html), em caminhos SVG numa grade de 24×24.
// Círculos e retângulos do original viraram caminhos para o Icone.qml desenhar tudo igual.
QtObject {
    readonly property var pasta: ["M3 7a2 2 0 0 1 2-2h4l2 2h8a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"]
    readonly property var busca: ["M18 11a7 7 0 1 1-14 0a7 7 0 1 1 14 0z", "M20 20l-4-4"]
    readonly property var navegador: [
        "M21 12a9 9 0 1 1-18 0a9 9 0 1 1 18 0z",
        "M3 12h18M12 3c3 3.5 3 14.5 0 18M12 3c-3 3.5-3 14.5 0 18"
    ]
    readonly property var terminal: [
        "M5 4h14a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2z",
        "M7 9l3 3-3 3M13 15h4"
    ]
    readonly property var controle: [
        "M6 11h4M8 9v4",
        "M16.3 10.5a0.8 0.8 0 1 1-1.6 0a0.8 0.8 0 1 1 1.6 0z",
        "M18.3 12.5a0.8 0.8 0 1 1-1.6 0a0.8 0.8 0 1 1 1.6 0z",
        "M7 5h10a5 5 0 0 1 5 5v1.5a4.5 4.5 0 0 1-8.2 2.6L13 13h-2l-.8 1.1A4.5 4.5 0 0 1 2 11.5V10a5 5 0 0 1 5-5z"
    ]
    readonly property var configuracoes: [
        "M15 12a3 3 0 1 1-6 0a3 3 0 1 1 6 0z",
        "M19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 1 1-4 0v-.1a1.7 1.7 0 0 0-1.1-1.5 1.7 1.7 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1a1.7 1.7 0 0 0 1.5-1.1 1.7 1.7 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.7 1.7 0 0 0 1.8.3H9a1.7 1.7 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.8V9a1.7 1.7 0 0 0 1.5 1H21a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1z"
    ]
    readonly property var downloads: ["M12 4v11M7 10l5 5 5-5", "M4 19h16"]
    readonly property var lixeira: ["M4 7h16M10 11v6M14 11v6", "M6 7l1 13h10l1-13M9 7V4h6v3"]
    readonly property var lua: ["M21 12.8A9 9 0 1 1 11.2 3a7 7 0 0 0 9.8 9.8z"]
    readonly property var expandir: ["M15 3h6v6", "M9 21H3v-6", "M21 3l-7 7", "M3 21l7-7"]
    readonly property var minimizar: ["M5 12h14"]
    readonly property var mais: ["M12 5v14M5 12h14"]
    readonly property var maleta: [
        "M5 7h14a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V9a2 2 0 0 1 2-2z",
        "M9 7V5a2 2 0 0 1 2-2h2a2 2 0 0 1 2 2v2", "M3 13h18"
    ]
    readonly property var grade: [
        "M4 4h6v6H4z", "M14 4h6v6h-6z", "M4 14h6v6H4z", "M14 14h6v6h-6z"
    ]
    readonly property var aplicativo: ["M6 3h12a3 3 0 0 1 3 3v12a3 3 0 0 1-3 3H6a3 3 0 0 1-3-3V6a3 3 0 0 1 3-3z", "M3 8h18"]
    // Navegador de pastas (Pastas.dc.html)
    readonly property var casa: ["M3 11l9-7 9 7", "M5 10v10h14V10"]
    readonly property var documento: ["M7 3h7l5 5v13H7z", "M14 3v5h5", "M10 13h6M10 17h6"]
    readonly property var imagem: ["M4 5h16v14H4z", "M4 15l5-5 4 4 3-3 4 4", "M15 9h.01"]
    readonly property var audio: [
        "M9 18V5l11-2v13",
        "M9 18a3 3 0 1 1-6 0a3 3 0 1 1 6 0z", "M20 16a3 3 0 1 1-6 0a3 3 0 1 1 6 0z"
    ]
    readonly property var video: ["M4 6h11v12H4z", "M15 10l5-3v10l-5-3"]
    readonly property var compactado: ["M7 3h10v18H7z", "M12 3v2M12 7v2M12 11v2"]
    readonly property var pacote: ["M3 7l9-4 9 4v10l-9 4-9-4z", "M3 7l9 4 9-4M12 11v10"]
    readonly property var disco: ["M3 13h18v6H3z", "M5 13l2-8h10l2 8", "M7 16h.01"]
    readonly property var usb: ["M9 2h6v6H9z", "M7 8h10v10a4 4 0 0 1-4 4h-2a4 4 0 0 1-4-4z"]
    readonly property var voltar: ["M15 6l-6 6 6 6"]
    readonly property var avancar: ["M9 6l6 6-6 6"]
    readonly property var lista: ["M8 6h12M8 12h12M8 18h12M4 6h.01M4 12h.01M4 18h.01"]
    readonly property var colunas: ["M5 4h14a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2z", "M9 4v16M15 4v16"]
    readonly property var maximizar: ["M6 4h12a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2z"]
    readonly property var fechar: ["M6 6l12 12M18 6L6 18"]
    readonly property var abrirPasta: ["M3 7a2 2 0 0 1 2-2h4l2 2h8a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z", "M10 13h6M13 10l3 3-3 3"]
    readonly property var sino: ["M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9", "M10.3 21a1.94 1.94 0 0 0 3.4 0"]
}
