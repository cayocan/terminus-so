import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "tema"

// Barra lateral do navegador de pastas: Favoritos, Locais (disco do sistema e mídias montadas) e Áreas.
Flickable {
    id: lateral

    // var (e não Pastas): Pastas cria esta janela, e o tipo explícito faria uma dependência circular.
    required property var pastas
    property string caminho
    property string livreSistema

    signal navegar(string destino)

    readonly property var favoritos: [
        { nome: qsTr("Início"), icone: Icones.casa, caminho: pastas.inicio },
        { nome: qsTr("Documentos"), icone: Icones.documento, caminho: pastas.pastasUsuario.DOCUMENTS },
        { nome: qsTr("Downloads"), icone: Icones.downloads, caminho: pastas.pastasUsuario.DOWNLOAD },
        { nome: qsTr("Imagens"), icone: Icones.imagem, caminho: pastas.pastasUsuario.PICTURES },
        { nome: qsTr("Música"), icone: Icones.audio, caminho: pastas.pastasUsuario.MUSIC },
        { nome: qsTr("Vídeos"), icone: Icones.video, caminho: pastas.pastasUsuario.VIDEOS }
    ]

    contentHeight: coluna.implicitHeight + 36
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    Accessible.role: Accessible.Pane
    Accessible.name: qsTr("Barra lateral")

    component Secao: Text {
        Layout.leftMargin: 12
        Layout.bottomMargin: 6
        color: Tema.textoDiscreto
        font.family: Tema.fonteTexto
        font.weight: Font.DemiBold
        font.pixelSize: Tema.tamanhoLegenda
        font.letterSpacing: Tema.espacamentoRotulo
        font.capitalization: Font.AllUppercase
    }

    // Pendrives e discos montados pelo sistema. Não dá para usar FolderListModel aqui: com a pasta
    // inexistente (nada montado ainda) ele lista a pasta atual no lugar.
    property var midias: []
    Process {
        id: buscaMidias
        running: true
        command: ["sh", "-c", "find /media/\"$USER\" /run/media/\"$USER\" -mindepth 1 -maxdepth 1 -type d 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: lateral.midias = text.split("\n").filter(l => l !== "")
        }
    }
    Timer {
        interval: 5000
        repeat: true
        running: lateral.visible
        onTriggered: buscaMidias.running = true
    }

    ColumnLayout {
        id: coluna
        x: 12
        y: 18
        width: lateral.width - 24
        spacing: 2

        Secao { text: qsTr("Favoritos") }
        Repeater {
            model: lateral.favoritos
            delegate: ItemLateral {
                required property var modelData
                Layout.fillWidth: true
                nome: modelData.nome
                icone: modelData.icone
                ativo: lateral.caminho === modelData.caminho
                onAcionado: lateral.navegar(modelData.caminho)
            }
        }

        Secao { text: qsTr("Locais"); Layout.topMargin: 16 }
        ItemLateral {
            Layout.fillWidth: true
            nome: qsTr("Disco do sistema")
            icone: Icones.disco
            nota: lateral.livreSistema
            ativo: lateral.caminho === "/"
            onAcionado: lateral.navegar("/")
        }
        Repeater {
            model: lateral.midias
            delegate: ItemLateral {
                required property string modelData
                Layout.fillWidth: true
                nome: modelData.substring(modelData.lastIndexOf("/") + 1)
                icone: Icones.usb
                ativo: lateral.caminho === modelData
                onAcionado: lateral.navegar(modelData)
            }
        }

        Secao {
            text: qsTr("Áreas")
            Layout.topMargin: 16
            visible: lateral.pastas.areas !== null && lateral.pastas.areas.lista.length > 0
        }
        Repeater {
            model: lateral.pastas.areas ? lateral.pastas.areas.lista : []
            delegate: ItemLateral {
                required property var modelData
                required property int index
                Layout.fillWidth: true
                nome: modelData.nome
                corPonto: index % 2 === 0 ? Tema.principal : Tema.profunda
                // Abre a área na tela principal (ela fica atrás das janelas).
                onAcionado: lateral.pastas.areas.atualizar(modelData.id, { minimizada: false })
            }
        }
    }
}
