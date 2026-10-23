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
    readonly property var sino:["M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9", "M10.3 21a1.94 1.94 0 0 0 3.4 0"]
}
