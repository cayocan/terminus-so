import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "tema"

// Central de notificações (docs/design/telas/Notificacoes.dc.html): painel à direita com o histórico
// agrupado por dia, Não perturbe e o botão "O que eu perdi?". Abre pelo widget ou por Super + N.
PanelWindow {
    id: painel

    required property Notificacoes central
    property bool aberta: false

    readonly property var localidade: Qt.locale("pt_BR")

    function abrir() { aberta = true }
    function fechar() {
        aberta = false
        // O que foi visto na central deixa de contar para o "O que eu perdi?".
        central.marcarLidas()
    }
    function alternar() { aberta ? fechar() : abrir() }

    function inicioDoDia(deslocamento) {
        const d = new Date(relogio.date)
        d.setHours(0, 0, 0, 0)
        return d.getTime() - deslocamento * 86400000
    }
    function grupos() {
        const hoje = inicioDoDia(0), ontem = inicioDoDia(1)
        const nomes = [qsTr("Hoje"), qsTr("Ontem"), qsTr("Antes")]
        const itens = [[], [], []]
        for (const h of central.historico)
            itens[h.chegada >= hoje ? 0 : h.chegada >= ontem ? 1 : 2].push(h)
        return nomes.map((nome, i) => ({ nome: nome, itens: itens[i] })).filter(g => g.itens.length > 0)
    }
    function tempo(chegada) {
        const minutos = Math.floor((relogio.date - chegada) / 60000)
        if (chegada >= inicioDoDia(0)) {
            if (minutos < 1) return qsTr("agora")
            if (minutos < 60) return qsTr("%1 min").arg(minutos)
            return qsTr("%1 h").arg(Math.floor(minutos / 60))
        }
        const data = new Date(chegada)
        return chegada >= inicioDoDia(1) ? data.toLocaleTimeString(localidade, "HH:mm")
                                         : data.toLocaleString(localidade, "dd/MM HH:mm")
    }

    SystemClock {
        id: relogio
        precision: SystemClock.Minutes
    }

    GlobalShortcut {
        appid: "terminus"
        name: "notificacoes"
        description: qsTr("Abrir a central de notificações")
        onPressed: painel.alternar()
    }

    visible: aberta
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "terminus-notificacoes"
    WlrLayershell.keyboardFocus: aberta ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    // Clique fora do painel fecha.
    MouseArea {
        anchors.fill: parent
        onClicked: painel.fechar()
    }

    Rectangle {
        id: lateral
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: Math.min(Tema.larguraCentral, painel.width)
        color: Tema.fundoCentral
        Accessible.role: Accessible.Pane
        Accessible.name: qsTr("Central de notificações")

        focus: painel.aberta
        Keys.onEscapePressed: painel.fechar()

        // A borda do design é só a da esquerda.
        Rectangle {
            width: 1
            height: parent.height
            color: Tema.bordaCentral
        }
        MouseArea { anchors.fill: parent }

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: Tema.preenchimentoCentralH
            anchors.rightMargin: Tema.preenchimentoCentralH
            anchors.topMargin: Tema.preenchimentoCentralV
            anchors.bottomMargin: Tema.preenchimentoCentralV
            spacing: 20

            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: qsTr("Notificações")
                    color: Tema.texto
                    font.family: Tema.fonteTitulo
                    font.weight: Font.DemiBold
                    font.pixelSize: Tema.tamanhoTituloCentral
                    font.letterSpacing: Tema.espacamentoHora
                    Accessible.role: Accessible.Heading
                }
                BotaoIcone {
                    nome: qsTr("Fechar painel")
                    icone: Icones.fechar
                    onAcionado: painel.fechar()
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Tema.alturaBotaoCentral
                    radius: Tema.raioBotaoCentral
                    color: toquePerdi.containsMouse ? Qt.alpha(Tema.principal, 0.2) : Qt.alpha(Tema.principal, 0.14)
                    border.color: Tema.bordaAviso
                    activeFocusOnTab: true
                    Accessible.role: Accessible.Button
                    Accessible.name: qsTr("O que eu perdi?")
                    Keys.onReturnPressed: perdi()
                    Keys.onSpacePressed: perdi()

                    function perdi() {
                        painel.central.oQueEuPerdi()
                        painel.aberta = false
                    }

                    Row {
                        anchors.centerIn: parent
                        spacing: 8
                        Icone {
                            anchors.verticalCenter: parent.verticalCenter
                            caminhos: Icones.altoFalante
                            tamanho: 16
                            espessura: 2
                            cor: Tema.textoTitulo
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: qsTr("O que eu perdi?")
                            color: Tema.textoTitulo
                            font.family: Tema.fonteTexto
                            font.weight: Font.DemiBold
                            font.pixelSize: Tema.tamanhoTextoMenor
                        }
                    }
                    MouseArea {
                        id: toquePerdi
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: parent.perdi()
                    }
                }

                // Interruptor de Não perturbe.
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Tema.alturaBotaoCentral
                    radius: Tema.raioBotaoCentral
                    color: toqueNp.containsMouse ? Tema.hover : "transparent"
                    border.color: Tema.bordaBotaoNeutro
                    activeFocusOnTab: true
                    Accessible.role: Accessible.CheckBox
                    Accessible.name: qsTr("Não perturbe")
                    Accessible.checked: painel.central.naoPerturbe
                    Keys.onSpacePressed: painel.central.naoPerturbe = !painel.central.naoPerturbe

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        Text {
                            Layout.fillWidth: true
                            text: qsTr("Não perturbe")
                            color: Tema.textoSecundario
                            font.family: Tema.fonteTexto
                            font.pixelSize: Tema.tamanhoTextoMenor
                        }
                        Interruptor {
                            ligado: painel.central.naoPerturbe
                            Accessible.name: qsTr("Não perturbe")
                            onAlternado: painel.central.naoPerturbe = !painel.central.naoPerturbe
                        }
                    }
                    MouseArea {
                        id: toqueNp
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: painel.central.naoPerturbe = !painel.central.naoPerturbe
                    }
                }
            }

            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentHeight: secoes.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: secoes
                    width: parent.width
                    spacing: 20

                    Repeater {
                        model: painel.aberta ? painel.grupos() : []
                        delegate: ColumnLayout {
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: 10

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.nome
                                    color: Tema.textoDiscreto
                                    font.family: Tema.fonteTexto
                                    font.weight: Font.DemiBold
                                    font.pixelSize: Tema.tamanhoLegenda
                                    font.letterSpacing: Tema.espacamentoRotulo
                                    font.capitalization: Font.AllUppercase
                                    Accessible.role: Accessible.Heading
                                }
                                Text {
                                    text: qsTr("Limpar")
                                    color: toqueLimpar.containsMouse ? Tema.linkHover : Tema.link
                                    font.family: Tema.fonteTexto
                                    font.pixelSize: Tema.tamanhoRotulo
                                    Accessible.role: Accessible.Button
                                    Accessible.name: qsTr("Limpar %1").arg(modelData.nome)
                                    MouseArea {
                                        id: toqueLimpar
                                        anchors.fill: parent
                                        anchors.margins: -8
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: painel.central.limpar(modelData.itens.map(h => h.id))
                                    }
                                }
                            }

                            Repeater {
                                model: modelData.itens
                                delegate: CartaoHistorico {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    registro: modelData
                                    tempo: painel.tempo(modelData.chegada)
                                }
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.topMargin: 8
                        visible: painel.central.historico.length === 0
                        text: qsTr("Nenhuma notificação nos últimos %1 dias.").arg(painel.central.diasGuardados)
                        wrapMode: Text.Wrap
                        color: Tema.textoDiscreto
                        font.family: Tema.fonteTexto
                        font.pixelSize: Tema.tamanhoTextoMenor
                    }
                }
            }
        }
    }
}
