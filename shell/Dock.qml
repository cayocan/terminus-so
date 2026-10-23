import QtQuick
import Quickshell
import Quickshell.Wayland
import "tema"

// Dock estilo macOS, acima das janelas, centralizada na borda inferior de cada tela.
PanelWindow {
    id: dock

    property Pastas pastas
    property var busca

    // "tela" abre uma tela do próprio Terminus; itens sem comando nem tela ainda não existem (Busca, Configurações...).
    readonly property var itens: [
        { nome: qsTr("Pastas"), icone: Icones.pasta, comando: [], appId: "", tela: "pastas" },
        { nome: qsTr("Busca"), icone: Icones.busca, comando: [], appId: "", tela: "busca" },
        { nome: qsTr("Navegador web"), icone: Icones.navegador, comando: ["firefox-esr"], appId: "firefox-esr" },
        { nome: qsTr("Terminal"), icone: Icones.terminal, comando: ["foot"], appId: "foot" },
        { nome: qsTr("Steam"), icone: Icones.controle, comando: ["steam"], appId: "steam" },
        { nome: qsTr("Configurações"), icone: Icones.configuracoes, comando: [], appId: "" }
    ]
    readonly property var atalhos: [
        { nome: qsTr("Pasta Downloads"), icone: Icones.downloads, comando: [], appId: "", tela: "downloads" },
        { nome: qsTr("Lixeira"), icone: Icones.lixeira, comando: [], appId: "", tela: "lixeira" }
    ]
    // Espaço acima da barra para o ícone ampliado pela lupa não ser cortado.
    readonly property int folgaLupa: Math.ceil(Tema.dockIcone * (Tema.dockLupa - 1)) + Tema.dockLupaSubida

    function janelaDo(appId) {
        if (appId === "") return null
        return ToplevelManager.toplevels.values.find(t => t.appId.toLowerCase() === appId) ?? null
    }

    function disponivel(entrada) {
        return entrada.comando.length > 0 || (entrada.tela !== undefined && pastas !== null)
    }

    function acionar(entrada) {
        if (entrada.tela === "busca") return busca.abrir()
        if (entrada.tela === "pastas") return pastas.abrir("")
        if (entrada.tela === "downloads") return pastas.abrir(pastas.pastasUsuario.DOWNLOAD)
        if (entrada.tela === "lixeira") return pastas.abrir(pastas.lixeira)
        const janela = janelaDo(entrada.appId)
        if (janela !== null) janela.activate()
        else Quickshell.execDetached(entrada.comando)
    }

    anchors.bottom: true
    implicitWidth: barra.width
    implicitHeight: Tema.dockAltura + Tema.dockMargem + folgaLupa
    exclusiveZone: Tema.dockAltura + Tema.dockMargem
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "terminus-dock"
    // Só a barra recebe cliques; a folga transparente deixa passar para as janelas embaixo.
    mask: Region { item: barra }

    Rectangle {
        id: barra
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Tema.dockMargem
        width: fileira.width + 2 * Tema.dockPreenchimento
        height: Tema.dockAltura
        radius: Tema.dockRaio
        color: Tema.vidroDock
        border.color: Tema.bordaDestaque
        Accessible.role: Accessible.ToolBar
        Accessible.name: qsTr("Dock")

        Row {
            id: fileira
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Tema.dockPreenchimentoBaixo
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Tema.dockEspaco

            Repeater {
                model: dock.itens
                delegate: ItemDock {
                    required property var modelData
                    nome: modelData.nome
                    icone: modelData.icone
                    disponivel: dock.disponivel(modelData)
                    aberto: modelData.tela === "pastas" ? dock.pastas !== null && dock.pastas.aberta
                          : ToplevelManager.toplevels.values.some(t => t.appId.toLowerCase() === modelData.appId)
                    onAcionado: dock.acionar(modelData)
                }
            }

            Rectangle {
                width: 1
                height: Tema.dockIcone - 4
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 10
                color: Tema.bordaDestaque
            }

            Repeater {
                model: dock.atalhos
                delegate: ItemDock {
                    required property var modelData
                    nome: modelData.nome
                    icone: modelData.icone
                    neutro: true
                    disponivel: dock.disponivel(modelData)
                    onAcionado: dock.acionar(modelData)
                }
            }
        }
    }
}
