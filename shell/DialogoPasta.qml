import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import "tema"

// Diálogo dentro da janela de pastas: pede um nome (nova pasta, renomear) ou uma confirmação.
Rectangle {
    id: dialogo

    property string titulo
    property string mensagem
    property string textoConfirmar: qsTr("Confirmar")
    property bool pedeTexto: true
    property bool perigo: false
    property var aoConfirmar: null

    function pedirNome(novoTitulo, valor, confirmar, acao) {
        titulo = novoTitulo
        mensagem = ""
        textoConfirmar = confirmar
        pedeTexto = true
        perigo = false
        aoConfirmar = acao
        campo.text = valor
        visible = true
        // Seleciona só o nome, sem a extensão, como os gerenciadores de arquivos costumam fazer.
        const ponto = valor.lastIndexOf(".")
        campo.select(0, ponto > 0 ? ponto : valor.length)
        campo.forceActiveFocus()
    }

    function confirmar(novoTitulo, novaMensagem, textoBotao, acao) {
        titulo = novoTitulo
        mensagem = novaMensagem
        textoConfirmar = textoBotao
        pedeTexto = false
        perigo = true
        aoConfirmar = acao
        visible = true
        caixa.forceActiveFocus()
    }

    function aceitar() {
        // O Enter chega ao campo e à caixa; só a primeira chamada vale.
        if (!visible) return
        if (pedeTexto && campo.text.trim() === "") return
        visible = false
        if (aoConfirmar) aoConfirmar(campo.text.trim())
    }

    signal fechado()

    visible: false
    color: Tema.sombraFundo
    onVisibleChanged: if (!visible) fechado()

    MouseArea {
        anchors.fill: parent
        onClicked: dialogo.visible = false
    }

    Rectangle {
        id: caixa
        anchors.centerIn: parent
        width: Math.min(Tema.larguraDialogo, parent.width - 48)
        height: coluna.implicitHeight + 2 * Tema.preenchimentoPainel
        radius: Tema.raioJanela
        color: Tema.vidroJanela
        border.color: Tema.bordaDestaque
        Accessible.role: Accessible.Dialog
        Accessible.name: dialogo.titulo
        Keys.onEscapePressed: dialogo.visible = false
        Keys.onReturnPressed: dialogo.aceitar()

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            id: coluna
            anchors.fill: parent
            anchors.margins: Tema.preenchimentoPainel
            spacing: Tema.espaco

            Text {
                Layout.fillWidth: true
                text: dialogo.titulo.toUpperCase()
                color: dialogo.perigo ? Tema.erroTexto : Tema.principal
                font.family: Tema.fonteTitulo
                font.weight: Font.DemiBold
                font.pixelSize: Tema.tamanhoSecao
                font.letterSpacing: Tema.espacamentoSecao
            }
            Text {
                Layout.fillWidth: true
                visible: dialogo.mensagem !== ""
                text: dialogo.mensagem
                wrapMode: Text.Wrap
                color: Tema.textoSecundario
                font.family: Tema.fonteTexto
                font.pixelSize: Tema.tamanhoTexto
            }
            TextField {
                id: campo
                Layout.fillWidth: true
                Layout.preferredHeight: Tema.alvoMinimo + 4
                visible: dialogo.pedeTexto
                color: Tema.texto
                font.family: Tema.fonteTexto
                font.pixelSize: Tema.tamanhoTexto
                leftPadding: 14
                background: Rectangle {
                    radius: Tema.raioBotaoArea
                    color: Tema.superficieNeutra
                    border.color: campo.activeFocus ? Tema.principal : Tema.bordaNeutra
                }
                onAccepted: dialogo.aceitar()
                Keys.onEscapePressed: dialogo.visible = false
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Item { Layout.fillWidth: true }
                BotaoTexto { texto: qsTr("Cancelar"); onAcionado: dialogo.visible = false }
                BotaoTexto { texto: dialogo.textoConfirmar; principal: true; perigo: dialogo.perigo; onAcionado: dialogo.aceitar() }
            }
        }
    }
}
