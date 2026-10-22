import QtQuick
import QtQuick.Shapes

// Ícone de traço desenhado a partir de caminhos SVG numa grade de 24×24 (ver tema/Icones.qml).
Item {
    id: icone

    property var caminhos: []
    property color cor: "white"
    property real tamanho: 24
    property real espessura: 1.6

    implicitWidth: tamanho
    implicitHeight: tamanho
    Accessible.ignored: true

    Shape {
        width: 24
        height: 24
        scale: icone.tamanho / 24
        transformOrigin: Item.TopLeft
        preferredRendererType: Shape.CurveRenderer
        antialiasing: true

        ShapePath {
            strokeColor: icone.cor
            strokeWidth: icone.espessura
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            // Cada caminho começa com M, então juntos viram subcaminhos de um só traçado.
            PathSvg { path: icone.caminhos.join(" ") }
        }
    }
}
