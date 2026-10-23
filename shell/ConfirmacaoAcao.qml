import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import Quickshell
import Quickshell.Wayland
import "tema"

// Pedido de confirmação de uma ação do sistema (servidor MCP), acima de tudo e com o teclado só para ele.
// Nível "confirmacao": Permitir ou Negar (a confirmação por voz entra com o assistente).
// Nível "senha": pede a senha do usuário; quem confere é o servidor, não esta tela.
PanelWindow {
    id: janela

    required property ServidorSistema servidor
    readonly property var pedido: servidor.fila.length > 0 ? servidor.fila[0] : null
    readonly property bool pedeSenha: pedido !== null && pedido.nivel === "senha"

    function permitir() {
        if (!pedido) return
        if (pedeSenha && campoSenha.text === "") return
        servidor.responder(pedido.id, true, pedeSenha ? { senha: campoSenha.text } : {})
        campoSenha.text = ""
    }
    function negar() {
        if (!pedido) return
        servidor.responder(pedido.id, false)
        campoSenha.text = ""
    }

    visible: pedido !== null
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: Tema.veuBusca
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "terminus-confirmacao"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // O foco só pega depois que a janela aparece: no primeiro pedido, a troca de pedido vem antes disso.
    function focar() {
        if (!pedido) return
        if (pedeSenha) campoSenha.forceActiveFocus()
        else caixa.forceActiveFocus()
    }
    onPedidoChanged: {
        campoSenha.text = ""
        Qt.callLater(focar)
    }
    onVisibleChanged: if (visible) Qt.callLater(focar)

    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(Tema.larguraConfirmacao, janela.width - 2 * Tema.margemTela)
        spacing: 20

        Esfera {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Tema.esferaConfirmacao
            Layout.preferredHeight: Tema.esferaConfirmacao
            estado: "atencao"
            animando: janela.visible
        }

        Rectangle {
            id: caixa
            Layout.fillWidth: true
            Layout.preferredHeight: conteudo.implicitHeight + 2 * Tema.preenchimentoPainel
            radius: Tema.raioJanela
            color: Tema.vidroJanela
            border.color: Tema.bordaConfirmacao
            Accessible.role: Accessible.AlertMessage
            Accessible.name: janela.pedido ? janela.pedido.resumo : ""
            Keys.onEscapePressed: janela.negar()
            Keys.onReturnPressed: botaoNegar.forceActiveFocus()

            ColumnLayout {
                id: conteudo
                anchors.fill: parent
                anchors.margins: Tema.preenchimentoPainel
                spacing: Tema.espaco

                Text {
                    Layout.fillWidth: true
                    text: janela.pedeSenha ? qsTr("SENHA NECESSÁRIA") : qsTr("CONFIRMAR AÇÃO")
                    color: Tema.atencaoTexto
                    font.family: Tema.fonteTitulo
                    font.weight: Font.DemiBold
                    font.pixelSize: Tema.tamanhoSecao
                    font.letterSpacing: Tema.espacamentoSecao
                }
                Text {
                    Layout.fillWidth: true
                    text: janela.pedido ? janela.pedido.resumo : ""
                    textFormat: Text.PlainText
                    wrapMode: Text.Wrap
                    color: Tema.textoTitulo
                    font.family: Tema.fonteTexto
                    font.weight: Font.DemiBold
                    font.pixelSize: Tema.tamanhoTextoGrande
                }
                Text {
                    Layout.fillWidth: true
                    text: janela.pedido ? qsTr("Pedido por %1 (ferramenta %2).").arg(janela.pedido.cliente).arg(janela.pedido.ferramenta) : ""
                    textFormat: Text.PlainText
                    wrapMode: Text.Wrap
                    color: Tema.textoDiscreto
                    font.family: Tema.fonteTexto
                    font.pixelSize: Tema.tamanhoRotulo
                }

                TextField {
                    id: campoSenha
                    Layout.fillWidth: true
                    Layout.preferredHeight: Tema.alvoMinimo + 4
                    visible: janela.pedeSenha
                    echoMode: TextInput.Password
                    placeholderText: qsTr("Sua senha")
                    placeholderTextColor: Tema.textoMarcador
                    color: Tema.texto
                    font.family: Tema.fonteTexto
                    font.pixelSize: Tema.tamanhoTexto
                    leftPadding: 14
                    Accessible.name: qsTr("Senha")
                    background: Rectangle {
                        radius: Tema.raioBotaoArea
                        color: Tema.superficieNeutra
                        border.color: campoSenha.activeFocus ? Tema.principal : Tema.bordaNeutra
                    }
                    onAccepted: janela.permitir()
                    Keys.onEscapePressed: janela.negar()
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    Text {
                        Layout.fillWidth: true
                        visible: janela.servidor.fila.length > 1
                        text: qsTr("+%1 na fila").arg(janela.servidor.fila.length - 1)
                        color: Tema.textoDiscreto
                        font.family: Tema.fonteTexto
                        font.pixelSize: Tema.tamanhoLegenda
                    }
                    Item { Layout.fillWidth: true; visible: janela.servidor.fila.length <= 1 }
                    BotaoTexto {
                        id: botaoNegar
                        texto: qsTr("Negar")
                        onAcionado: janela.negar()
                    }
                    BotaoTexto {
                        texto: janela.pedeSenha ? qsTr("Confirmar com senha") : qsTr("Permitir")
                        principal: true
                        onAcionado: janela.permitir()
                    }
                }
            }
        }
    }
}
