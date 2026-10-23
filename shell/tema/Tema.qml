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
    readonly property color textoCorpo: "#B8D2E2"
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
    readonly property color vidroDock: Qt.rgba(12 / 255, 24 / 255, 40 / 255, 0.72)
    readonly property color vidroArea: Qt.rgba(10 / 255, 22 / 255, 38 / 255, 0.5)
    readonly property color destaqueSuave: Qt.alpha(principal, 0.12)
    readonly property color superficieNeutra: Qt.rgba(1, 1, 1, 0.04)
    readonly property color hover: Qt.rgba(1, 1, 1, 0.08)
    readonly property color trilhoBarra: Qt.rgba(1, 1, 1, 0.08)
    readonly property color atencaoSuave: Qt.rgba(245 / 255, 158 / 255, 66 / 255, 0.14)
    readonly property color bordaDestaque: Qt.alpha(principal, 0.28)
    readonly property color bordaNeutra: Qt.rgba(156 / 255, 201 / 255, 224 / 255, 0.16)
    readonly property color selecaoFundo: Qt.alpha(principal, 0.12)
    readonly property color sombraJanela: Qt.rgba(0, 0, 0, 0.55)

    // Tipografia
    readonly property string fonteTitulo: "Orbitron"
    readonly property string fonteTexto: "Inter"
    readonly property int tamanhoHora: 84
    readonly property int tamanhoTituloTela: 40
    readonly property int tamanhoData: 20
    readonly property int tamanhoSecao: 13
    readonly property int tamanhoTexto: 15
    readonly property int tamanhoTextoMenor: 14
    readonly property int tamanhoTextoGrande: 18
    readonly property int tamanhoRotulo: 13
    readonly property int tamanhoLegenda: 12
    readonly property real espacamentoSecao: 2.5
    readonly property real espacamentoHora: 2
    readonly property real espacamentoRotulo: 1.5
    readonly property real espacamentoNome: 6

    // Raios
    readonly property int raioCartao: 20
    readonly property int raioJanela: 18
    readonly property int raioPilula: 24
    readonly property int raioIcone: 14
    readonly property int raioNotificacao: 18
    readonly property int raioArea: 22
    readonly property int raioIconeNotificacao: 12
    readonly property int raioItemDock: 16

    // Medidas
    readonly property int alvoMinimo: 44
    readonly property int margemTela: 64
    readonly property int espaco: 16
    readonly property int dockAltura: 92
    readonly property int dockIcone: 60
    readonly property int dockRaio: 28
    readonly property int dockMargem: 28
    readonly property int dockEspaco: 14
    readonly property int dockPreenchimento: 18
    readonly property int dockPreenchimentoBaixo: 12
    readonly property int dockIndicador: 5
    readonly property real dockLupa: 1.32
    readonly property int dockLupaSubida: 10
    readonly property int margemTopo: 56
    readonly property int larguraColuna: 420
    readonly property int larguraHardware: 380
    readonly property int topoHardware: 304
    readonly property int preenchimentoPainel: 24
    readonly property int alturaBarra: 6
    readonly property int iconeNotificacao: 40

    // Áreas de atalho (Main.dc.html e AreasDock.dc.html)
    readonly property int larguraArea: 420
    readonly property int alturaArea: 236
    readonly property int larguraMinimaArea: 240
    readonly property int alturaMinimaArea: 160
    readonly property int preenchimentoAreaH: 22
    readonly property int preenchimentoAreaV: 20
    readonly property int espacoAtalhos: 12
    readonly property int iconeAtalho: 64
    readonly property int raioAtalho: 18
    readonly property int raioBotaoArea: 12
    readonly property int areaMinimizada: 72
    readonly property int alcaArea: 14
    readonly property int raioAlca: 4
    readonly property int passoEncaixe: 8
    readonly property color bordaTracejada: Qt.alpha(principal, 0.6)
    readonly property color brilhoSelecao: Qt.alpha(principal, 0.18)
    readonly property color etiquetaMedida: Qt.alpha(principal, 0.16)

    // Janelas e navegador de pastas (Pastas.dc.html)
    readonly property int larguraJanela: 1440
    readonly property int alturaJanela: 820
    readonly property int alturaTitulo: 52
    readonly property int larguraBotaoJanela: 56
    readonly property color fecharHover: "#C4314B"
    readonly property int alturaFerramentas: 64
    readonly property int larguraLateral: 260
    readonly property int alturaItemLateral: 40
    readonly property int raioItemLateral: 10
    readonly property int alturaRodape: 40
    readonly property int larguraBuscaPasta: 260
    readonly property int alturaItemPasta: 150
    readonly property int larguraMinimaItemPasta: 180
    readonly property int raioItemPasta: 16
    readonly property int raioIconeItemPasta: 14
    readonly property int alturaLinhaPasta: 44
    readonly property int bordaRedimensionar: 6
    readonly property color linhaDivisoria: Qt.rgba(156 / 255, 201 / 255, 224 / 255, 0.12)
    readonly property color bordaCampo: Qt.rgba(156 / 255, 201 / 255, 224 / 255, 0.2)
    readonly property color textoDesativado: "#6F8BA0"
    readonly property color textoMarcador: "#7E9DB3"
    readonly property color corPasta: "#5B9BFF"
    readonly property color pastaSuave: Qt.rgba(91 / 255, 155 / 255, 1, 0.12)
    readonly property color itemSelecionado: Qt.alpha(principal, 0.10)
    readonly property color bordaSelecionado: Qt.alpha(principal, 0.6)
    readonly property color modoAtivo: Qt.alpha(principal, 0.18)

    // Busca global (Busca.dc.html)
    readonly property color veuBusca: Qt.rgba(2 / 255, 5 / 255, 10 / 255, 0.72)
    readonly property int topoBusca: 110
    readonly property int esferaBusca: 150
    readonly property int larguraBusca: 880
    readonly property int raioBusca: 26
    readonly property color bordaBusca: Qt.alpha(principal, 0.45)
    readonly property int alturaCampoBusca: 76
    readonly property int tamanhoCampoBusca: 24
    readonly property int alturaMaximaResultados: 560
    readonly property int alturaResultado: 60
    readonly property int raioResultado: 14
    readonly property int tamanhoResultado: 16
    readonly property int alturaRodapeBusca: 48
    readonly property color textoMeta: "#9FBACB"
    readonly property color corApp: "#5B9BFF"
    readonly property color fundoIconeResultado: Qt.alpha(principal, 0.10)

    // Central de notificações e "O que eu perdi?" (Notificacoes.dc.html)
    readonly property int larguraCentral: 480
    readonly property color fundoCentral: Qt.rgba(8 / 255, 16 / 255, 28 / 255, 0.94)
    readonly property color bordaCentral: Qt.alpha(principal, 0.3)
    readonly property int preenchimentoCentralV: 32
    readonly property int preenchimentoCentralH: 26
    readonly property int tamanhoTituloCentral: 20
    readonly property int alturaBotaoCentral: 48
    readonly property int raioBotaoCentral: 14
    readonly property color bordaBotaoNeutro: Qt.rgba(156 / 255, 201 / 255, 224 / 255, 0.22)
    readonly property color fundoCartaoHistorico: Qt.rgba(12 / 255, 24 / 255, 40 / 255, 0.75)
    readonly property color bordaCartaoHistorico: Qt.rgba(156 / 255, 201 / 255, 224 / 255, 0.14)
    readonly property int raioCartaoHistorico: 16
    readonly property int iconeHistorico: 36
    readonly property int raioIconeHistorico: 10
    readonly property color atencaoBorda: Qt.rgba(245 / 255, 165 / 255, 74 / 255, 0.4)
    readonly property color fundoAviso: Qt.rgba(12 / 255, 28 / 255, 46 / 255, 0.95)
    readonly property color bordaAviso: Qt.alpha(principal, 0.5)
    readonly property int larguraAviso: 440
    readonly property int topoAviso: 40
    readonly property int tempoAviso: 6000
    readonly property int tamanhoResumo: 24
    readonly property int larguraResumo: 800

    // Configurações e conectores (Config.dc.html)
    readonly property int larguraConfig: 1520
    readonly property int alturaConfig: 900
    readonly property int larguraCategorias: 300
    readonly property int alturaCategoria: 44
    readonly property int raioCategoria: 12
    readonly property int tamanhoCategoria: 15
    readonly property int preenchimentoConfigV: 32
    readonly property int preenchimentoConfigH: 36
    readonly property int tamanhoTituloConfig: 28
    readonly property color fundoCartaoConector: Qt.rgba(12 / 255, 24 / 255, 40 / 255, 0.7)
    readonly property int raioCartaoConector: 20
    readonly property int iconeConector: 48
    readonly property int raioIconeConector: 14
    readonly property int tamanhoNomeConector: 17
    readonly property int larguraMinimaCartao: 300
    readonly property color bordaBotaoCartao: Qt.rgba(156 / 255, 201 / 255, 224 / 255, 0.25)
    readonly property color fundoNeutroIcone: Qt.rgba(1, 1, 1, 0.06)
    readonly property int larguraInterruptor: 40
    readonly property int alturaInterruptor: 22

    // Menus e diálogos
    readonly property int raioMenu: 14
    readonly property int alturaItemMenu: 40
    readonly property int larguraMenu: 220
    readonly property int larguraDialogo: 460
    readonly property color sombraFundo: Qt.rgba(0, 0, 0, 0.45)
}
