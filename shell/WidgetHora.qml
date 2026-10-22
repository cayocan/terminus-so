import QtQuick
import Quickshell
import "tema"

// Hora e data no canto superior esquerdo da tela principal.
Column {
    id: widget

    readonly property var localidade: Qt.locale("pt_BR")

    spacing: 6
    Accessible.role: Accessible.StaticText
    Accessible.name: hora.text + ", " + data.text

    SystemClock {
        id: relogio
        precision: SystemClock.Minutes
    }

    Text {
        id: hora
        text: relogio.date.toLocaleTimeString(widget.localidade, "HH:mm")
        color: Tema.textoTitulo
        font.family: Tema.fonteTitulo
        font.weight: Font.DemiBold
        font.pixelSize: Tema.tamanhoHora
        font.letterSpacing: Tema.espacamentoHora
        lineHeight: 1
    }

    Text {
        id: data
        text: relogio.date.toLocaleDateString(widget.localidade, "dddd, d 'de' MMMM 'de' yyyy")
        color: Tema.textoTerciario
        font.family: Tema.fonteTexto
        font.pixelSize: Tema.tamanhoData
    }
}
