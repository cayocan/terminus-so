import QtQuick
import "tema"

// Tela principal (docs/design/telas/Main.dc.html): esfera no centro, hora e hardware à esquerda,
// notificações à direita. A dock fica numa janela própria (Dock.qml), acima das janelas dos apps.
Item {
    id: tela

    property string estadoAssistente: "repouso"
    property string nomeAssistente: "Terminus"
    property Notificacoes notificacoes
    property Areas areas
    // As áreas de atalho aparecem só na tela principal (a primeira), para não se repetirem.
    property bool mostrarAreas: true
    property string areaRedimensionando: ""

    // Tamanho do monitor: a janela passa por medidas provisórias ao abrir, o monitor não.
    property size tamanhoTela

    function semearSePreciso() {
        if (mostrarAreas && areas && areas.precisaSemear && tamanhoTela.width > 0)
            areas.semear(tamanhoTela.width, tamanhoTela.height)
    }
    onTamanhoTelaChanged: semearSePreciso()
    Connections {
        target: tela.areas
        function onPrecisaSemearChanged() { tela.semearSePreciso() }
    }

    readonly property var rotulosEstado: ({
        repouso: qsTr("Em repouso"),
        escutando: qsTr("Escutando"),
        pensando: qsTr("Pensando"),
        falando: qsTr("Falando"),
        programando: qsTr("Programando"),
        atencao: qsTr("Precisa da sua atenção"),
        erro: qsTr("Algo deu errado")
    })

    Fundo {
        anchors.fill: parent
        centro: Qt.point(esfera.x + esfera.width / 2, esfera.y + esfera.height / 2)
        raioEsfera: esfera.width / 2
    }

    // Clique direito no fundo: criar uma área de atalhos ali. Clique esquerdo sai do modo de redimensionar.
    MouseArea {
        anchors.fill: parent
        enabled: tela.mostrarAreas
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            tela.areaRedimensionando = ""
            if (mouse.button !== Qt.RightButton) return
            // A área nova nasce onde foi o clique, mas sem passar da borda nem entrar na faixa da dock.
            const x = Math.min(mouse.x, tela.width - Tema.larguraArea)
            const y = Math.min(mouse.y, tela.height - Tema.dockAltura - Tema.dockMargem - Tema.alturaArea)
            menuContexto.abrir(mouse.x, mouse.y, [
                { texto: qsTr("Nova área de atalhos"), acao: () => tela.areas.criar(x, y) }
            ])
        }
    }

    WidgetHora {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: Tema.margemTela
        anchors.topMargin: Tema.margemTopo
        width: Tema.larguraColuna
    }

    WidgetHardware {
        anchors.left: parent.left
        anchors.leftMargin: Tema.margemTela
        y: Tema.topoHardware
        width: Tema.larguraHardware
    }

    WidgetNotificacoes {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: Tema.margemTela
        anchors.topMargin: Tema.margemTopo
        width: Tema.larguraColuna
        central: tela.notificacoes
    }

    Esfera {
        id: esfera
        anchors.horizontalCenter: parent.horizontalCenter
        y: tela.height * 150 / 1080
        width: Math.min(tela.width, tela.height) * 0.48
        height: width
        estado: tela.estadoAssistente
    }

    Column {
        anchors.top: esfera.bottom
        anchors.topMargin: 18
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 18

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: tela.nomeAssistente.toUpperCase()
            color: Tema.principal
            font.family: Tema.fonteTitulo
            font.weight: Font.DemiBold
            font.pixelSize: Tema.tamanhoTexto
            font.letterSpacing: Tema.espacamentoNome
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: tela.rotulosEstado[tela.estadoAssistente] ?? tela.rotulosEstado.repouso
            color: Tema.textoCorpo
            font.family: Tema.fonteTexto
            font.pixelSize: Tema.tamanhoTextoGrande
        }
    }

    Repeater {
        model: tela.mostrarAreas && tela.areas ? tela.areas.lista : []
        delegate: AreaAtalhos {
            required property var modelData
            dados: modelData
            areas: tela.areas
            menu: menuContexto
            limites: Qt.size(tela.width, tela.height - Tema.dockAltura - Tema.dockMargem)
            redimensionando: tela.areaRedimensionando === modelData.id
            onRedimensionarAlternado: tela.areaRedimensionando = redimensionando ? "" : modelData.id
        }
    }

    MenuContexto {
        id: menuContexto
        anchors.fill: parent
    }
}
