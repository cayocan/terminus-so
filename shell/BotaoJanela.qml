import QtQuick
import "tema"

// Botão da barra de título (minimizar, maximizar, fechar), à direita como no Windows.
Rectangle {
    id: botao

    property string nome
    property var icone: []
    property bool fechar: false

    signal acionado()

    implicitWidth: Tema.larguraBotaoJanela
    implicitHeight: Tema.alturaTitulo
    color: toque.containsMouse ? (fechar ? Tema.fecharHover : Tema.hover) : "transparent"
    Accessible.role: Accessible.Button
    Accessible.name: nome

    Icone {
        anchors.centerIn: parent
        caminhos: botao.icone
        tamanho: 14
        espessura: 2
        cor: toque.containsMouse && botao.fechar ? "white" : Tema.textoSecundario
    }

    MouseArea {
        id: toque
        anchors.fill: parent
        hoverEnabled: true
        onClicked: botao.acionado()
    }
}
