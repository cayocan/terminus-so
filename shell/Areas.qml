import QtQuick
import Quickshell
import Quickshell.Io
import "tema"

// Áreas de atalho do usuário, salvas na camada pessoal (nunca sobrescrita por atualizações da base).
// Cada área: { id, nome, x, y, largura, altura, minimizada, atalhos: [ids de .desktop] }
Item {
    id: areas

    property var lista: []
    // Arquivo ainda não existe: a tela principal chama semear() com o tamanho da tela.
    property bool precisaSemear: false
    // Pedido de diálogo para a janela de diálogos: { tipo: "renomear" | "atalho", areaId }
    property var dialogo: null

    readonly property string caminho: Quickshell.env("HOME") + "/.config/terminus/pessoal/areas.json"

    // Com o arquivo ilegível, nada é gravado: a camada pessoal nunca é sobrescrita sem o usuário saber.
    property bool somenteLeitura: false

    function salvar() {
        if (somenteLeitura) return
        arquivo.setText(JSON.stringify({ versao: 1, areas: lista }, null, 2))
    }

    function buscar(id) {
        return lista.find(a => a.id === id)
    }

    function atualizar(id, mudancas) {
        lista = lista.map(a => a.id === id ? Object.assign({}, a, mudancas) : a)
        salvar()
    }

    function criar(x, y) {
        const id = "area-" + Date.now()
        lista = lista.concat([{
            id: id, nome: qsTr("Nova área"), x: x, y: y,
            largura: Tema.larguraArea, altura: Tema.alturaArea, minimizada: false, atalhos: []
        }])
        salvar()
        dialogo = { tipo: "renomear", areaId: id }
    }

    function excluir(id) {
        lista = lista.filter(a => a.id !== id)
        salvar()
    }

    function adicionarAtalho(id, entrada) {
        const area = buscar(id)
        if (area && !area.atalhos.includes(entrada))
            atualizar(id, { atalhos: area.atalhos.concat([entrada]) })
    }

    function removerAtalho(id, entrada) {
        const area = buscar(id)
        if (area) atualizar(id, { atalhos: area.atalhos.filter(e => e !== entrada) })
    }

    // Primeira execução: as áreas do design (Main.dc.html), com os apps que vêm na ISO.
    function semear(largura, altura) {
        precisaSemear = false
        lista = [
            {
                id: "area-jogos", nome: qsTr("Jogos"),
                x: largura - Tema.margemTela - Tema.larguraArea, y: Math.round(altura * 600 / 1080),
                largura: Tema.larguraArea, altura: Tema.alturaArea, minimizada: false,
                atalhos: ["steam"]
            },
            {
                id: "area-trabalho", nome: qsTr("Trabalho"),
                x: Tema.margemTela, y: Math.round(altura * 760 / 1080),
                largura: Tema.larguraArea, altura: Tema.alturaArea, minimizada: true,
                atalhos: ["firefox-esr", "foot"]
            }
        ]
        salvar()
    }

    FileView {
        id: arquivo
        path: areas.caminho
        blockLoading: true
        printErrors: false
        onLoaded: {
            try {
                areas.lista = JSON.parse(text()).areas ?? []
            } catch (e) {
                console.warn("areas.json inválido; as áreas não serão salvas até o arquivo ser corrigido:", e)
                areas.somenteLeitura = true
                areas.lista = []
            }
        }
        onLoadFailed: erro => {
            if (erro === FileViewError.FileNotFound) areas.precisaSemear = true
        }
    }
}
