import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import "tema"

// Pasta em leque na dock (AreasDock.dc.html): os arquivos mais recentes de uma pasta saem do ícone em
// arco, cada um com o nome ao lado. Clicar abre o arquivo; o último item abre a pasta no navegador.
PopupWindow {
    id: leque

    required property var pastas
    property string pasta
    property Item ancora
    property bool aberto: false

    // Itens mais recentes primeiro (o primeiro fica mais perto da dock), mais o "Abrir pasta" no fim.
    readonly property var itens: {
        const lista = []
        const total = Math.min(modelo.count, Tema.itensLeque)
        for (let i = 0; i < total; i++) {
            const caminho = modelo.get(i, "filePath")
            const t = Arquivos.tipo(modelo.get(i, "fileSuffix"), modelo.get(i, "fileIsDir"))
            lista.push({ nome: modelo.get(i, "fileName"), caminho: caminho, icone: t.icone, cor: t.cor })
        }
        lista.push({
            nome: modelo.count === 0 ? qsTr("Pasta vazia · abrir em Pastas") : qsTr("Abrir em Pastas"),
            caminho: "", icone: Icones.abrirPasta, cor: Tema.textoSecundario, abrirPasta: true
        })
        return lista
    }
    readonly property int largura: 360

    // Clicar no ícone com o leque aberto: o clique fora já o fechou (grabFocus), então não reabre.
    property double fechadoEm: 0
    function alternar() {
        if (aberto) aberto = false
        else if (Date.now() - fechadoEm > 300) aberto = true
    }

    function acionar(item) {
        aberto = false
        if (item.abrirPasta) pastas.abrir(pasta)
        else Quickshell.execDetached(["xdg-open", item.caminho])
    }

    FolderListModel {
        id: modelo
        folder: leque.pasta !== "" ? "file://" + leque.pasta : ""
        sortField: FolderListModel.Time
        showDirsFirst: false
        showDotAndDotDot: false
        showHidden: false
    }

    visible: aberto && ancora !== null
    anchor.item: ancora
    anchor.edges: Edges.Top
    anchor.gravity: Edges.Top
    // Clicar fora fecha (o compositor tira o foco do popup).
    grabFocus: true
    onVisibleChanged: if (!visible) {
        aberto = false
        fechadoEm = Date.now()
    }
    implicitWidth: largura
    implicitHeight: itens.length * Tema.passoLeque + 24
    color: "transparent"

    Repeater {
        model: leque.itens
        delegate: Item {
            id: linha
            required property var modelData
            required property int index
            // Arco do design: cada item sobe 62 px, inclina um pouco mais e se afasta do eixo.
            readonly property real deslocamento: 30 + index * index * 4

            width: leque.largura
            height: Tema.tamanhoItemLeque
            y: leque.height - (index + 1) * Tema.passoLeque
            Accessible.role: Accessible.Button
            Accessible.name: modelData.nome

            Row {
                anchors.right: parent.right
                // A borda direita do quadrado fica deslocamento px à direita do centro do ícone da dock.
                anchors.rightMargin: leque.largura / 2 - linha.deslocamento
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12
                rotation: -2 - linha.index * 2.2

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(nome.implicitWidth + 24, leque.largura - Tema.tamanhoItemLeque - 60)
                    height: Tema.alturaEtiquetaLeque
                    radius: Tema.raioEtiquetaLeque
                    color: Tema.fundoEtiquetaLeque
                    border.color: Tema.bordaEtiquetaLeque
                    Text {
                        id: nome
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideMiddle
                        text: linha.modelData.nome
                        color: Tema.texto
                        font.family: Tema.fonteTexto
                        font.pixelSize: Tema.tamanhoRotulo
                    }
                }
                Rectangle {
                    width: Tema.tamanhoItemLeque
                    height: Tema.tamanhoItemLeque
                    radius: Tema.raioItemLeque
                    color: Tema.fundoItemLeque
                    border.color: Tema.bordaItemLeque
                    transform: Translate { x: toque.containsMouse ? -4 : 0 }
                    Icone {
                        anchors.centerIn: parent
                        caminhos: linha.modelData.icone
                        tamanho: 24
                        cor: linha.modelData.cor
                    }
                }
            }

            MouseArea {
                id: toque
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: leque.acionar(linha.modelData)
            }
        }
    }
}
