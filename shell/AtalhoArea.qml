import QtQuick
import Quickshell
import "tema"

// Um atalho dentro de uma área: ícone do app e nome. Clique abre; clique direito pede o menu.
Item {
    id: atalho

    required property string entradaId
    // Alguns apps mudaram o nome do .desktop (ex.: foot); a busca aproximada cobre esses casos.
    // Ler applications.values faz a busca se refazer quando a lista de apps termina de carregar.
    readonly property var entrada: {
        DesktopEntries.applications.values
        return DesktopEntries.byId(entradaId) ?? DesktopEntries.heuristicLookup(entradaId)
    }
    readonly property string nome: entrada ? entrada.name : entradaId

    signal menuPedido(real x, real y)

    implicitHeight: coluna.implicitHeight
    Accessible.role: Accessible.Button
    Accessible.name: nome
    activeFocusOnTab: true
    Keys.onReturnPressed: if (entrada) entrada.execute()

    Column {
        id: coluna
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width
        spacing: 8

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Tema.iconeAtalho
            height: Tema.iconeAtalho
            radius: Tema.raioAtalho
            color: toque.containsMouse ? Qt.alpha(Tema.principal, 0.2) : Tema.destaqueSuave
            border.color: atalho.activeFocus ? Tema.principal : Tema.bordaDestaque
            opacity: atalho.entrada ? 1 : 0.5

            Image {
                id: imagem
                anchors.centerIn: parent
                width: 32
                height: 32
                sourceSize: Qt.size(64, 64)
                source: atalho.entrada && atalho.entrada.icon !== "" ? Quickshell.iconPath(atalho.entrada.icon, true) : ""
                visible: status === Image.Ready
                asynchronous: true
            }
            Icone {
                anchors.centerIn: parent
                visible: !imagem.visible
                caminhos: Icones.aplicativo
                tamanho: 30
                cor: Tema.principal
            }
        }

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: atalho.nome
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
            color: Tema.textoSecundario
            font.family: Tema.fonteTexto
            font.pixelSize: Tema.tamanhoRotulo
        }
    }

    MouseArea {
        id: toque
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: atalho.entrada ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) atalho.menuPedido(mouse.x, mouse.y)
            else if (atalho.entrada) atalho.entrada.execute()
        }
    }
}
