import QtQuick
import Quickshell
import Quickshell.Wayland
import "tema"

// Dock estilo macOS, acima das janelas, centralizada na borda inferior de cada tela.
PanelWindow {
    id: dock

    // Itens sem comando são telas do Terminus que ainda não existem (Pastas, Busca, Configurações...).
    readonly property var itens: [
        { nome: qsTr("Pastas"), icone: Icones.pasta, comando: [], appId: "" },
        { nome: qsTr("Busca"), icone: Icones.busca, comando: [], appId: "" },
        { nome: qsTr("Navegador web"), icone: Icones.navegador, comando: ["firefox-esr"], appId: "firefox-esr" },
        { nome: qsTr("Terminal"), icone: Icones.terminal, comando: ["foot"], appId: "foot" },
        { nome: qsTr("Steam"), icone: Icones.controle, comando: ["steam"], appId: "steam" },
        { nome: qsTr("Configurações"), icone: Icones.configuracoes, comando: [], appId: "" }
    ]
    readonly property var atalhos: [
        { nome: qsTr("Pasta Downloads"), icone: Icones.downloads, comando: [], appId: "" },
        { nome: qsTr("Lixeira"), icone: Icones.lixeira, comando: [], appId: "" }
    ]
    // Espaço acima da barra para o ícone ampliado pela lupa não ser cortado.
    readonly property int folgaLupa: Math.ceil(Tema.dockIcone * (Tema.dockLupa - 1)) + Tema.dockLupaSubida

    function janelaDo(appId) {
        if (appId === "") return null
        return ToplevelManager.toplevels.values.find(t => t.appId.toLowerCase() === appId) ?? null
    }

    function acionar(entrada) {
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
                    disponivel: modelData.comando.length > 0
                    aberto: ToplevelManager.toplevels.values.some(t => t.appId.toLowerCase() === modelData.appId)
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
                    disponivel: modelData.comando.length > 0
                    onAcionado: dock.acionar(modelData)
                }
            }
        }
    }
}
