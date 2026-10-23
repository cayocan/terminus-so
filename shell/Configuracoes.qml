import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "tema"

// Preferências do usuário e a janela de Configurações (criada no primeiro uso).
// Ficam na camada pessoal, em ~/.config/terminus/pessoal/configuracoes.json, que as atualizações da base
// nunca sobrescrevem.
Item {
    id: controleConfig

    property string nomeAssistente: "Terminus"
    property var servidor
    // Conectores: { id: { bomDia: bool } }. Ligar e conectar de verdade chega com o servidor MCP.
    property var conectores: ({})
    readonly property bool aberta: carregador.active
    // Arquivo ilegível: nada é gravado por cima, como nas áreas de atalho.
    property bool somenteLeitura: false

    // Categorias da barra lateral (Config.dc.html). "pronta" diz se a página já funciona.
    readonly property var categorias: [
        { id: "aparencia", nome: qsTr("Aparência e cores"), icone: Icones.aparencia, pronta: true },
        { id: "assistente", nome: qsTr("Esfera e assistente"), icone: Icones.esfera, pronta: true },
        { id: "ia", nome: qsTr("IAs de programação"), icone: Icones.codigo, pronta: false },
        { id: "conectores", nome: qsTr("Conectores"), icone: Icones.tomada, pronta: true },
        { id: "areas", nome: qsTr("Áreas e dock"), icone: Icones.grade, pronta: false },
        { id: "rede", nome: qsTr("Rede"), icone: Icones.wifi, pronta: false },
        { id: "som", nome: qsTr("Som"), icone: Icones.altoFalante, pronta: false },
        { id: "telas", nome: qsTr("Telas"), icone: Icones.tela, pronta: false },
        { id: "usuarios", nome: qsTr("Usuários e segurança"), icone: Icones.usuario, pronta: true },
        { id: "atualizacoes", nome: qsTr("Atualizações e camada pessoal"), icone: Icones.atualizar, pronta: false },
        { id: "jogos", nome: qsTr("Jogos e compatibilidade"), icone: Icones.controle, pronta: false }
    ]

    function abrir(categoria) {
        const destino = categoria || "aparencia"
        if (!carregador.active) {
            carregador.categoriaInicial = destino
            carregador.active = true
            return
        }
        carregador.item.categoria = destino
        carregador.item.visible = true
        Hyprland.dispatch("focuswindow title:^Configurações$")
    }
    function fechar() { carregador.active = false }

    function definirPreset(nome) {
        Tema.preset = nome
        salvar()
    }
    function definirNome(nome) {
        nomeAssistente = nome
        salvar()
    }
    function definirBomDia(id, valor) {
        const copia = Object.assign({}, conectores)
        copia[id] = Object.assign({}, copia[id], { bomDia: valor })
        conectores = copia
        salvar()
    }

    function salvar() {
        if (somenteLeitura) return
        arquivo.setText(JSON.stringify({
            versao: 1, preset: Tema.preset, nomeAssistente: nomeAssistente, conectores: conectores
        }, null, 2))
    }

    FileView {
        id: arquivo
        path: Quickshell.env("HOME") + "/.config/terminus/pessoal/configuracoes.json"
        blockLoading: true
        printErrors: false
        onLoaded: {
            try {
                const dados = JSON.parse(text())
                if (Tema.nomesPresets.includes(dados.preset)) Tema.preset = dados.preset
                if (dados.nomeAssistente) controleConfig.nomeAssistente = dados.nomeAssistente
                controleConfig.conectores = dados.conectores ?? {}
            } catch (e) {
                console.warn("configuracoes.json inválido; as configurações não serão salvas até o arquivo ser corrigido:", e)
                controleConfig.somenteLeitura = true
            }
        }
    }

    LazyLoader {
        id: carregador
        property string categoriaInicial

        JanelaConfiguracoes {
            configuracoes: controleConfig
            categoria: carregador.categoriaInicial
        }
    }
}
