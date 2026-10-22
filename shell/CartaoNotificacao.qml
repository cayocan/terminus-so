import QtQuick
import QtQuick.Layouts
import Quickshell
import "tema"

// Uma notificação na lista da tela principal. Clicar dispensa.
Rectangle {
    id: cartao

    required property var notificacao
    property string tempo

    readonly property string icone: notificacao.appIcon !== "" ? Quickshell.iconPath(notificacao.appIcon, true) : ""
    readonly property string titulo: notificacao.summary !== "" ? notificacao.summary : notificacao.appName

    implicitHeight: linha.implicitHeight + 32
    radius: Tema.raioNotificacao
    color: toque.containsMouse ? Qt.tint(Tema.vidroPainel, Tema.hover) : Tema.vidroPainel
    border.color: Tema.bordaDestaque
    Accessible.role: Accessible.Button
    Accessible.name: titulo + ". " + notificacao.body
    Accessible.description: qsTr("Dispensar notificação")

    RowLayout {
        id: linha
        anchors.fill: parent
        anchors.leftMargin: 18
        anchors.rightMargin: 18
        anchors.topMargin: 16
        anchors.bottomMargin: 16
        spacing: 14

        Rectangle {
            Layout.preferredWidth: Tema.iconeNotificacao
            Layout.preferredHeight: Tema.iconeNotificacao
            Layout.alignment: Qt.AlignTop
            radius: Tema.raioIconeNotificacao
            color: Tema.destaqueSuave

            Image {
                id: imagem
                anchors.centerIn: parent
                width: 24
                height: 24
                sourceSize: Qt.size(48, 48)
                source: cartao.icone
                visible: status === Image.Ready
                asynchronous: true
            }
            Icone {
                anchors.centerIn: parent
                visible: !imagem.visible
                caminhos: Icones.sino
                tamanho: 20
                espessura: 1.8
                cor: Tema.principal
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: cartao.titulo
                    color: Tema.texto
                    font.family: Tema.fonteTexto
                    font.weight: Font.DemiBold
                    font.pixelSize: Tema.tamanhoTexto
                }
                Text {
                    text: cartao.tempo
                    color: Tema.textoDiscreto
                    font.family: Tema.fonteTexto
                    font.pixelSize: Tema.tamanhoLegenda
                }
            }
            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: cartao.notificacao.body
                textFormat: Text.PlainText
                wrapMode: Text.Wrap
                maximumLineCount: 3
                elide: Text.ElideRight
                lineHeight: 1.4
                color: Tema.textoCorpo
                font.family: Tema.fonteTexto
                font.pixelSize: Tema.tamanhoTextoMenor
            }
        }
    }

    MouseArea {
        id: toque
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: cartao.notificacao.dismiss()
    }
}
