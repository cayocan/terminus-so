pragma Singleton
import QtQuick

// Valores visuais do Terminus SO, tirados de docs/design/README.md.
// Toda tela nova usa estes valores em vez de cores e medidas soltas.
QtObject {
    id: tema

    property string preset: "Jarvis clássico"

    readonly property var presets: ({
        "Jarvis clássico": { principal: "#22D3EE", profunda: "#1E6BFF" },
        "Mark":            { principal: "#F5B83D", profunda: "#E5484D" },
        "Stealth":         { principal: "#D6DEE6", profunda: "#6B7A8C" }
    })
    readonly property var nomesPresets: Object.keys(presets)
    readonly property var presetAtual: presets[preset] !== undefined ? presets[preset] : presets["Jarvis clássico"]

    // Destaques (mudam com o preset)
    readonly property color principal: presetAtual.principal
    readonly property color profunda: presetAtual.profunda
    readonly property color principalClaro: "#7FE3F3"

    // Fundo
    readonly property color fundo: "#04070D"
    readonly property color grade: Qt.rgba(156 / 255, 201 / 255, 224 / 255, 0.045)
    readonly property int passoGrade: 48

    // Texto
    readonly property color textoTitulo: "#F2FAFF"
    readonly property color texto: "#E6F4FB"
    readonly property color textoSecundario: "#CFE6F2"
    readonly property color textoTerciario: "#A9C7DA"
    readonly property color textoDiscreto: "#8FB3CC"
    readonly property color link: "#7FD8EA"
    readonly property color linkHover: "#B9EEF7"

    // Estados
    readonly property color atencao: "#F5A54A"
    readonly property color atencaoTexto: "#F8C27F"
    readonly property color erro: "#F05252"
    readonly property color erroTexto: "#FCA5A5"
    readonly property color sucesso: "#34D399"
    readonly property color sucessoTexto: "#6EE7B7"
    readonly property color programando: "#3B82F6"
    readonly property color programandoTexto: "#9CC0FA"

    // Material de vidro
    readonly property color vidroPainel: Qt.rgba(10 / 255, 22 / 255, 38 / 255, 0.62)
    readonly property color vidroJanela: Qt.rgba(9 / 255, 18 / 255, 32 / 255, 0.95)
    readonly property color bordaDestaque: Qt.alpha(principal, 0.28)
    readonly property color bordaNeutra: Qt.rgba(156 / 255, 201 / 255, 224 / 255, 0.16)
    readonly property color selecaoFundo: Qt.alpha(principal, 0.12)
    readonly property color sombraJanela: Qt.rgba(0, 0, 0, 0.55)

    // Tipografia
    readonly property string fonteTitulo: "Orbitron"
    readonly property string fonteTexto: "Inter"
    readonly property int tamanhoHora: 84
    readonly property int tamanhoTituloTela: 40
    readonly property int tamanhoSecao: 13
    readonly property int tamanhoTexto: 15
    readonly property int tamanhoTextoGrande: 18
    readonly property int tamanhoLegenda: 12
    readonly property real espacamentoSecao: 2.5

    // Raios
    readonly property int raioCartao: 20
    readonly property int raioJanela: 18
    readonly property int raioPilula: 24
    readonly property int raioIcone: 14

    // Medidas
    readonly property int alvoMinimo: 44
    readonly property int margemTela: 64
    readonly property int espaco: 16
    readonly property int dockAltura: 92
    readonly property int dockIcone: 60
    readonly property int dockRaio: 28
    readonly property int dockMargem: 28
}
