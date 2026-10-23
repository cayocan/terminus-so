import QtQuick
import QtQuick.Layouts
import "tema"

// Página Conectores (Config.dc.html). Os conectores em si chegam na fase 6, sobre o servidor MCP da fase 3, e
// criar conector com a IA de programação na fase 5; por enquanto dá para escolher o que entra no bom dia.
ColumnLayout {
    id: pagina

    required property var configuracoes

    readonly property var lista: [
        { id: "email", nome: qsTr("E-mail"), icone: Icones.email,
          descricao: qsTr("Lê sua caixa de entrada e separa o que é importante.") },
        { id: "kanban", nome: qsTr("Kanban do trabalho"), icone: Icones.kanban,
          descricao: qsTr("Tarefas atribuídas a você, prazos e o que precisa de atenção.") },
        { id: "github", nome: qsTr("GitHub"), icone: Icones.git,
          descricao: qsTr("Pull requests do Terminus SO aguardando sua aprovação.") },
        { id: "calendario", nome: qsTr("Calendário"), icone: Icones.calendario,
          descricao: qsTr("Compromissos do dia e lembretes antes de cada reunião.") },
        { id: "nuvem", nome: qsTr("Armazenamento na nuvem"), icone: Icones.nuvem,
          descricao: qsTr("Sincroniza suas pastas com o serviço de nuvem que você usa.") }
    ]

    spacing: 26

    RowLayout {
        Layout.fillWidth: true
        spacing: 24
        TituloPagina {
            Layout.fillWidth: true
            titulo: qsTr("Conectores")
            descricao: qsTr("Ligue seus serviços ao sistema. O que estiver marcado com “Entra no bom dia” aparece no seu resumo da manhã.")
        }
        BotaoTexto {
            Layout.alignment: Qt.AlignBottom
            texto: qsTr("+  Criar conector")
            principal: true
            enabled: false
            opacity: 0.5
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: aviso.implicitHeight + 28
        radius: Tema.raioBotaoArea
        color: Tema.destaqueSuave
        border.color: Tema.bordaDestaque
        Text {
            id: aviso
            anchors.fill: parent
            anchors.margins: 14
            wrapMode: Text.Wrap
            text: qsTr("Os conectores passam a funcionar com o servidor MCP do sistema, e “Criar conector” com a IA de programação. Por enquanto, o que você marcar para o bom dia fica guardado.")
            color: Tema.textoSecundario
            font.family: Tema.fonteTexto
            font.pixelSize: Tema.tamanhoTextoMenor
        }
    }

    GridLayout {
        id: grade
        Layout.fillWidth: true
        columns: Math.max(1, Math.min(3, Math.floor((width + 18) / (Tema.larguraMinimaCartao + 18))))
        columnSpacing: 18
        rowSpacing: 18

        Repeater {
            model: pagina.lista
            delegate: CartaoConector {
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.alignment: Qt.AlignTop
                conector: modelData
                bomDia: pagina.configuracoes.conectores[modelData.id]?.bomDia ?? false
                onBomDiaAlternado: pagina.configuracoes.definirBomDia(modelData.id, !bomDia)
            }
        }
    }
}
