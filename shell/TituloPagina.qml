import QtQuick
import QtQuick.Layouts
import "tema"

// Título e descrição no alto de uma página das Configurações.
ColumnLayout {
    property string titulo
    property string descricao

    spacing: 8

    Text {
        text: parent.titulo
        color: Tema.texto
        font.family: Tema.fonteTitulo
        font.weight: Font.DemiBold
        font.pixelSize: Tema.tamanhoTituloConfig
        font.letterSpacing: Tema.espacamentoHora
        Accessible.role: Accessible.Heading
    }
    Text {
        Layout.fillWidth: true
        Layout.maximumWidth: 720
        visible: text !== ""
        text: parent.descricao
        wrapMode: Text.Wrap
        color: Tema.textoTerciario
        font.family: Tema.fonteTexto
        font.pixelSize: Tema.tamanhoTexto
    }
}
