import QtQuick
import QtQuick.Layouts
import Quickshell
import "tema"

// Uma linha de resultado da busca global: ícone, nome, detalhe e dica à direita.
Rectangle {
    id: resultado

    // { nome, meta, icone (caminhos) ou iconeApp (nome do tema), cor, dica }
    required property var dados
    property bool selecionado: false

    signal acionado()
    signal apontado()

    implicitHeight: Math.max(Tema.alturaResultado, linha.implicitHeight + 20)
    radius: Tema.raioResultado
    color: selecionado ? Tema.selecaoFundo : (toque.containsMouse ? Qt.rgba(1, 1, 1, 0.05) : "transparent")
    border.color: selecionado ? Tema.bordaBusca : "transparent"
    Accessible.role: Accessible.ListItem
    Accessible.name: dados.nome
    Accessible.description: dados.meta
    Accessible.selected: selecionado

    RowLayout {
        id: linha
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        spacing: 14

        Rectangle {
            Layout.preferredWidth: Tema.iconeNotificacao
            Layout.preferredHeight: Tema.iconeNotificacao
            radius: Tema.raioIconeNotificacao
            color: Tema.fundoIconeResultado

            Image {
                id: imagem
                anchors.centerIn: parent
                width: 26
                height: 26
                sourceSize: Qt.size(52, 52)
                source: resultado.dados.iconeApp ? Quickshell.iconPath(resultado.dados.iconeApp, true) : ""
                visible: status === Image.Ready
                asynchronous: true
            }
            Icone {
                anchors.centerIn: parent
                visible: !imagem.visible
                caminhos: resultado.dados.icone ?? Icones.aplicativo
                tamanho: 20
                espessura: 1.7
                cor: resultado.dados.cor
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Text {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: resultado.dados.nome
                color: Tema.texto
                font.family: Tema.fonteTexto
                font.weight: Font.DemiBold
                font.pixelSize: Tema.tamanhoResultado
            }
            Text {
                Layout.fillWidth: true
                visible: text !== ""
                elide: Text.ElideMiddle
                text: resultado.dados.meta
                color: Tema.textoMeta
                font.family: Tema.fonteTexto
                font.pixelSize: Tema.tamanhoRotulo
            }
        }

        Text {
            visible: resultado.selecionado
            text: resultado.dados.dica ?? qsTr("Abrir")
            color: Tema.textoDiscreto
            font.family: Tema.fonteTexto
            font.pixelSize: Tema.tamanhoLegenda
        }
    }

    MouseArea {
        id: toque
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: resultado.apontado()
        onClicked: resultado.acionado()
    }
}
