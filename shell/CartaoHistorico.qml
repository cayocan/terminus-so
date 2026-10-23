import QtQuick
import QtQuick.Layouts
import Quickshell
import "tema"

// Uma notificação guardada no histórico (central de notificações e aviso flutuante).
// As urgentes usam a cor de atenção.
Rectangle {
    id: cartao

    // { app, titulo, corpo, icone, urgente }
    required property var registro
    property string tempo
    property bool aviso: false
    property int tamanhoIcone: Tema.iconeHistorico

    readonly property color tom: registro.urgente ? Tema.atencao : Tema.principal

    implicitHeight: linha.implicitHeight + 28
    radius: aviso ? Tema.raioNotificacao : Tema.raioCartaoHistorico
    color: aviso ? Tema.fundoAviso : Tema.fundoCartaoHistorico
    border.color: registro.urgente ? Tema.atencaoBorda : (aviso ? Tema.bordaAviso : Tema.bordaCartaoHistorico)
    Accessible.role: Accessible.StaticText
    Accessible.name: registro.app + ". " + registro.titulo + ". " + registro.corpo

    RowLayout {
        id: linha
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.topMargin: 14
        anchors.bottomMargin: 14
        spacing: 12

        Rectangle {
            Layout.preferredWidth: cartao.tamanhoIcone
            Layout.preferredHeight: cartao.tamanhoIcone
            Layout.alignment: Qt.AlignTop
            radius: Tema.raioIconeHistorico
            color: Qt.alpha(cartao.tom, 0.14)

            Image {
                id: imagem
                anchors.centerIn: parent
                width: cartao.tamanhoIcone * 0.55
                height: width
                sourceSize: Qt.size(48, 48)
                source: cartao.registro.icone ? Quickshell.iconPath(cartao.registro.icone, true) : ""
                visible: status === Image.Ready
                asynchronous: true
            }
            Icone {
                anchors.centerIn: parent
                visible: !imagem.visible
                caminhos: Icones.sino
                tamanho: cartao.tamanhoIcone / 2
                espessura: 1.8
                cor: cartao.tom
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: cartao.registro.titulo ? cartao.registro.app + " · " + cartao.registro.titulo : cartao.registro.app
                    textFormat: Text.PlainText
                    color: Tema.texto
                    font.family: Tema.fonteTexto
                    font.weight: Font.DemiBold
                    font.pixelSize: cartao.aviso ? Tema.tamanhoTexto : Tema.tamanhoTextoMenor
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
                text: cartao.registro.corpo ?? ""
                textFormat: Text.PlainText
                wrapMode: Text.Wrap
                maximumLineCount: 3
                elide: Text.ElideRight
                lineHeight: 1.4
                color: Tema.textoCorpo
                font.family: Tema.fonteTexto
                font.pixelSize: cartao.aviso ? Tema.tamanhoTextoMenor : Tema.tamanhoRotulo
            }
        }
    }
}
