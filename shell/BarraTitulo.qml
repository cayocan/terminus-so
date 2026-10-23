import QtQuick
import QtQuick.Layouts
import "tema"

// Barra de título das janelas do Terminus: ícone e nome à esquerda, minimizar, maximizar e fechar à
// direita (como no Windows). Arrastar move a janela; clique duplo maximiza. Inclui a linha divisória.
ColumnLayout {
    id: barra

    required property var janelaAlvo
    property string titulo
    property var icone: []

    signal fecharPedido()

    spacing: 0

    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: Tema.alturaTitulo

        MouseArea {
            anchors.fill: parent
            onPressed: barra.janelaAlvo.startSystemMove()
            onDoubleClicked: barra.janelaAlvo.maximized = !barra.janelaAlvo.maximized
        }
        Row {
            anchors.left: parent.left
            anchors.leftMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10
            Icone {
                anchors.verticalCenter: parent.verticalCenter
                caminhos: barra.icone
                tamanho: 18
                espessura: 1.8
                cor: Tema.principal
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: barra.titulo
                color: Tema.texto
                font.family: Tema.fonteTexto
                font.weight: Font.DemiBold
                font.pixelSize: Tema.tamanhoTextoMenor
            }
        }
        Row {
            anchors.right: parent.right
            // O Hyprland não minimiza; minimizar esconde a janela e a dock a mostra de novo.
            BotaoJanela { nome: qsTr("Minimizar janela"); icone: Icones.minimizar; onAcionado: barra.janelaAlvo.visible = false }
            BotaoJanela {
                nome: barra.janelaAlvo.maximized ? qsTr("Restaurar janela") : qsTr("Maximizar janela")
                icone: Icones.maximizar
                onAcionado: barra.janelaAlvo.maximized = !barra.janelaAlvo.maximized
            }
            BotaoJanela { nome: qsTr("Fechar janela"); icone: Icones.fechar; fechar: true; onAcionado: barra.fecharPedido() }
        }
    }
    Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Tema.linhaDivisoria }
}
