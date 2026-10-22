import QtQuick
import QtQuick.Layouts
import "tema"

// Painel de hardware ao vivo: CPU, GPU (quando houver uma AMD) e memória.
Rectangle {
    id: widget

    property bool ativo: true
    readonly property var localidade: Qt.locale("pt_BR")

    function gb(bytes) {
        return (bytes / 1073741824).toLocaleString(localidade, "f", 1)
    }
    function graus(valor) {
        return isNaN(valor) ? "" : qsTr("%1 °C").arg(Math.round(valor))
    }
    function juntar(partes) {
        return partes.filter(p => p !== "").join(" · ")
    }

    implicitHeight: conteudo.implicitHeight + 2 * Tema.preenchimentoPainel
    radius: Tema.raioCartao
    color: Tema.vidroPainel
    border.color: Tema.bordaDestaque

    Hardware {
        id: hw
        ativo: widget.ativo && widget.visible
    }

    ColumnLayout {
        id: conteudo
        anchors.fill: parent
        anchors.margins: Tema.preenchimentoPainel
        spacing: 20

        RowLayout {
            Layout.fillWidth: true
            Text {
                Layout.fillWidth: true
                text: qsTr("HARDWARE")
                color: Tema.principal
                font.family: Tema.fonteTitulo
                font.weight: Font.DemiBold
                font.pixelSize: Tema.tamanhoSecao
                font.letterSpacing: Tema.espacamentoSecao
            }
            Text {
                text: qsTr("ao vivo")
                color: Tema.textoDiscreto
                font.family: Tema.fonteTexto
                font.pixelSize: Tema.tamanhoRotulo
            }
        }

        LinhaUso {
            Layout.fillWidth: true
            titulo: qsTr("CPU")
            subtitulo: hw.nomeCpu
            valor: Math.round(hw.usoCpu) + "%"
            fracao: hw.usoCpu / 100
            detalhe: widget.juntar([widget.graus(hw.temperaturaCpu),
                                    hw.nucleos > 0 ? qsTr("%1 núcleos").arg(hw.nucleos) : ""])
        }

        LinhaUso {
            Layout.fillWidth: true
            visible: hw.temGpu
            titulo: qsTr("GPU")
            valor: Math.round(hw.usoGpu) + "%"
            fracao: hw.usoGpu / 100
            detalhe: widget.juntar([widget.graus(hw.temperaturaGpu),
                                    hw.vramTotal > 0 ? qsTr("VRAM %1 / %2 GB").arg(widget.gb(hw.vramUsada)).arg(widget.gb(hw.vramTotal)) : ""])
        }

        LinhaUso {
            Layout.fillWidth: true
            titulo: qsTr("Memória")
            valor: qsTr("%1 GB").arg(widget.gb(hw.memoriaUsada))
            fracao: hw.memoriaTotal > 0 ? hw.memoriaUsada / hw.memoriaTotal : 0
            detalhe: qsTr("de %1 GB").arg(Math.round(hw.memoriaTotal / 1073741824))
            corBarra: Tema.profunda
        }
    }
}
