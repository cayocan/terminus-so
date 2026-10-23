import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import "tema"

// Página Esfera e assistente: o nome que aparece embaixo da esfera. Voz e palavra de ativação entram com
// o assistente.
ColumnLayout {
    id: pagina

    required property var configuracoes

    function salvarNome() {
        const nome = campo.text.trim()
        if (nome !== "" && nome !== configuracoes.nomeAssistente) configuracoes.definirNome(nome)
        campo.text = configuracoes.nomeAssistente
    }

    spacing: 26

    TituloPagina {
        Layout.fillWidth: true
        titulo: qsTr("Esfera e assistente")
        descricao: qsTr("O nome do seu assistente aparece embaixo da esfera. A voz e a palavra de ativação chegam junto com o assistente.")
    }

    ColumnLayout {
        Layout.preferredWidth: 460
        spacing: 10
        Text {
            text: qsTr("Nome do assistente")
            color: Tema.textoSecundario
            font.family: Tema.fonteTexto
            font.weight: Font.DemiBold
            font.pixelSize: Tema.tamanhoTextoMenor
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            TextField {
                id: campo
                Layout.fillWidth: true
                Layout.preferredHeight: Tema.alvoMinimo + 4
                text: pagina.configuracoes.nomeAssistente
                maximumLength: 24
                color: Tema.texto
                font.family: Tema.fonteTexto
                font.pixelSize: Tema.tamanhoTexto
                leftPadding: 14
                Accessible.name: qsTr("Nome do assistente")
                background: Rectangle {
                    radius: Tema.raioBotaoArea
                    color: Tema.superficieNeutra
                    border.color: campo.activeFocus ? Tema.principal : Tema.bordaCampo
                }
                onAccepted: pagina.salvarNome()
            }
            BotaoTexto {
                texto: qsTr("Salvar")
                principal: true
                onAcionado: pagina.salvarNome()
            }
        }
    }
}
