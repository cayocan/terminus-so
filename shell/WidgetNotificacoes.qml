import QtQuick
import QtQuick.Layouts
import Quickshell
import "tema"

// As notificações mais recentes no canto superior direito, com o botão Não perturbe.
ColumnLayout {
    id: widget

    required property Notificacoes central
    property int maximo: 3

    // Pede a central de notificações (título e "Ver todas").
    signal centralPedida()

    spacing: 12

    SystemClock {
        id: relogio
        precision: SystemClock.Minutes
    }

    function tempoDesde(chegada) {
        const minutos = Math.floor((relogio.date - chegada) / 60000)
        if (minutos < 1) return qsTr("agora")
        if (minutos < 60) return qsTr("%1 min").arg(minutos)
        return qsTr("%1 h").arg(Math.floor(minutos / 60))
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 4
        Layout.rightMargin: 4

        Text {
            Layout.fillWidth: true
            text: qsTr("NOTIFICAÇÕES")
            color: Tema.principal
            font.family: Tema.fonteTitulo
            font.weight: Font.DemiBold
            font.pixelSize: Tema.tamanhoSecao
            font.letterSpacing: Tema.espacamentoSecao
            Accessible.role: Accessible.Button
            Accessible.name: qsTr("Abrir a central de notificações")
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: widget.centralPedida()
            }
        }

        Rectangle {
            id: botao
            Layout.preferredHeight: Tema.alvoMinimo
            Layout.preferredWidth: rotuloBotao.implicitWidth + 28
            radius: height / 2
            color: widget.central.naoPerturbe ? Tema.selecaoFundo : (toqueBotao.containsMouse ? Tema.hover : "transparent")
            border.color: widget.central.naoPerturbe ? Tema.principal : Tema.bordaDestaque
            activeFocusOnTab: true
            Accessible.role: Accessible.CheckBox
            Accessible.name: qsTr("Não perturbe")
            Accessible.checked: widget.central.naoPerturbe
            Keys.onSpacePressed: widget.central.naoPerturbe = !widget.central.naoPerturbe

            Row {
                id: rotuloBotao
                anchors.centerIn: parent
                spacing: 8
                Icone {
                    anchors.verticalCenter: parent.verticalCenter
                    caminhos: Icones.lua
                    tamanho: 16
                    espessura: 1.8
                    cor: widget.central.naoPerturbe ? Tema.principal : Tema.textoSecundario
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: qsTr("Não perturbe")
                    color: widget.central.naoPerturbe ? Tema.principalClaro : Tema.textoSecundario
                    font.family: Tema.fonteTexto
                    font.pixelSize: Tema.tamanhoRotulo
                }
            }

            MouseArea {
                id: toqueBotao
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: widget.central.naoPerturbe = !widget.central.naoPerturbe
            }
        }
    }

    Repeater {
        model: widget.central.naoPerturbe ? [] : widget.central.lista.slice(0, widget.maximo)
        delegate: CartaoNotificacao {
            required property var modelData
            Layout.fillWidth: true
            notificacao: modelData.notificacao
            tempo: widget.tempoDesde(modelData.chegada)
        }
    }

    Text {
        Layout.fillWidth: true
        Layout.leftMargin: 4
        visible: widget.central.naoPerturbe || widget.central.lista.length === 0
        text: widget.central.naoPerturbe ? qsTr("Não perturbe ativado. As notificações ficam guardadas.")
                                         : qsTr("Nenhuma notificação nova.")
        wrapMode: Text.Wrap
        color: Tema.textoDiscreto
        font.family: Tema.fonteTexto
        font.pixelSize: Tema.tamanhoTextoMenor
    }

    Text {
        Layout.leftMargin: 4
        visible: widget.central.historico.length > 0
        text: widget.central.naoLidas > 0 ? qsTr("Ver todas · %1 não lidas").arg(widget.central.naoLidas) : qsTr("Ver todas")
        color: toqueVer.containsMouse ? Tema.linkHover : Tema.link
        font.family: Tema.fonteTexto
        font.pixelSize: Tema.tamanhoRotulo
        Accessible.role: Accessible.Button
        Accessible.name: text
        MouseArea {
            id: toqueVer
            anchors.fill: parent
            anchors.margins: -8
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: widget.centralPedida()
        }
    }
}
