import QtQuick
import QtQuick.Layouts
import "tema"

// Um conector na página Conectores: ícone, estado, descrição, interruptores e a ação.
// Enquanto o servidor MCP não existe, todos aparecem como "Não configurado" e a ação fica desativada.
Rectangle {
    id: cartao

    // { id, nome, icone, descricao }
    required property var conector
    property bool bomDia: false
    property bool configurado: false

    signal bomDiaAlternado()

    implicitHeight: coluna.implicitHeight + 40
    radius: Tema.raioCartaoConector
    color: Tema.fundoCartaoConector
    border.color: Tema.bordaNeutra
    Accessible.role: Accessible.Grouping
    Accessible.name: conector.nome

    ColumnLayout {
        id: coluna
        anchors.fill: parent
        anchors.margins: 20
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            spacing: 14
            Rectangle {
                Layout.preferredWidth: Tema.iconeConector
                Layout.preferredHeight: Tema.iconeConector
                radius: Tema.raioIconeConector
                color: cartao.configurado ? Tema.destaqueSuave : Tema.fundoNeutroIcone
                Icone {
                    anchors.centerIn: parent
                    caminhos: cartao.conector.icone
                    tamanho: 24
                    espessura: 1.7
                    cor: cartao.configurado ? Tema.principal : Tema.textoMeta
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                Text {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: cartao.conector.nome
                    color: Tema.texto
                    font.family: Tema.fonteTexto
                    font.weight: Font.DemiBold
                    font.pixelSize: Tema.tamanhoNomeConector
                }
                Row {
                    spacing: 6
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 8
                        height: 8
                        radius: 4
                        color: cartao.configurado ? Tema.sucesso : Tema.textoMeta
                    }
                    Text {
                        text: cartao.configurado ? qsTr("Conectado") : qsTr("Não configurado")
                        color: cartao.configurado ? Tema.sucesso : Tema.textoMeta
                        font.family: Tema.fonteTexto
                        font.pixelSize: Tema.tamanhoRotulo
                    }
                }
            }
        }

        Text {
            Layout.fillWidth: true
            Layout.minimumHeight: 40
            text: cartao.conector.descricao
            wrapMode: Text.Wrap
            lineHeight: 1.45
            color: Tema.textoTerciario
            font.family: Tema.fonteTexto
            font.pixelSize: Tema.tamanhoTextoMenor
        }

        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Tema.linhaDivisoria }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: Tema.alvoMinimo
            Text {
                Layout.fillWidth: true
                text: qsTr("Ativo")
                color: Tema.textoSecundario
                font.family: Tema.fonteTexto
                font.pixelSize: Tema.tamanhoTextoMenor
            }
            // Só dá para ativar um conector configurado.
            Interruptor {
                ligado: cartao.configurado
                ativo: false
                Accessible.name: qsTr("%1 ativo").arg(cartao.conector.nome)
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: Tema.alvoMinimo
            Text {
                Layout.fillWidth: true
                text: qsTr("Entra no bom dia")
                color: Tema.textoSecundario
                font.family: Tema.fonteTexto
                font.pixelSize: Tema.tamanhoTextoMenor
            }
            Interruptor {
                ligado: cartao.bomDia
                Accessible.name: qsTr("%1 entra no bom dia").arg(cartao.conector.nome)
                onAlternado: cartao.bomDiaAlternado()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Tema.alvoMinimo
            radius: Tema.raioBotaoArea
            color: "transparent"
            border.color: Tema.bordaBotaoCartao
            opacity: 0.5
            Accessible.role: Accessible.Button
            Accessible.name: qsTr("Conectar %1 (em breve)").arg(cartao.conector.nome)
            Text {
                anchors.centerIn: parent
                text: qsTr("Conectar · em breve")
                color: Tema.textoSecundario
                font.family: Tema.fonteTexto
                font.weight: Font.DemiBold
                font.pixelSize: Tema.tamanhoTextoMenor
            }
        }
    }
}
