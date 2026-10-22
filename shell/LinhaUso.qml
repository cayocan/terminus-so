import QtQuick
import QtQuick.Layouts
import "tema"

// Uma linha do widget de hardware: nome, valor, barra de uso e detalhe.
ColumnLayout {
    id: linha

    property string titulo
    property string subtitulo
    property string valor
    property real fracao: 0
    property string detalhe
    property color corBarra: Tema.principal

    spacing: 8
    Accessible.role: Accessible.ProgressBar
    Accessible.name: titulo + " " + valor + (detalhe !== "" ? ", " + detalhe : "")

    RowLayout {
        Layout.fillWidth: true

        Text {
            Layout.fillWidth: true
            elide: Text.ElideRight
            textFormat: Text.StyledText
            text: "<b>" + linha.titulo + "</b>" +
                  (linha.subtitulo !== "" ? " <font color='" + Tema.textoDiscreto + "'>" + linha.subtitulo + "</font>" : "")
            color: Tema.texto
            font.family: Tema.fonteTexto
            font.pixelSize: Tema.tamanhoTexto
        }
        Text {
            text: linha.valor
            color: Tema.texto
            font.family: Tema.fonteTitulo
            font.pixelSize: Tema.tamanhoTextoGrande
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: Tema.alturaBarra
        radius: Tema.alturaBarra / 2
        color: Tema.trilhoBarra

        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, linha.fracao))
            height: parent.height
            radius: parent.radius
            color: linha.corBarra
            Behavior on width { SmoothedAnimation { velocity: 200 } }
        }
    }

    Text {
        visible: linha.detalhe !== ""
        text: linha.detalhe
        color: Tema.textoDiscreto
        font.family: Tema.fonteTexto
        font.pixelSize: Tema.tamanhoRotulo
    }
}
