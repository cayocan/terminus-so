import QtQuick
import "tema"

// Bordas e cantos para redimensionar as janelas do Terminus (elas não têm decoração do compositor).
// Vai por último dentro da janela, ocupando-a toda. Os cantos vêm depois das bordas para ficarem por cima.
Item {
    id: bordas

    required property var janelaAlvo

    Repeater {
        model: bordas.janelaAlvo.maximized ? [] : [
            { bordas: Qt.LeftEdge, cursor: Qt.SizeHorCursor },
            { bordas: Qt.RightEdge, cursor: Qt.SizeHorCursor },
            { bordas: Qt.TopEdge, cursor: Qt.SizeVerCursor },
            { bordas: Qt.BottomEdge, cursor: Qt.SizeVerCursor },
            { bordas: Qt.TopEdge | Qt.LeftEdge, cursor: Qt.SizeFDiagCursor },
            { bordas: Qt.BottomEdge | Qt.RightEdge, cursor: Qt.SizeFDiagCursor },
            { bordas: Qt.TopEdge | Qt.RightEdge, cursor: Qt.SizeBDiagCursor },
            { bordas: Qt.BottomEdge | Qt.LeftEdge, cursor: Qt.SizeBDiagCursor }
        ]
        delegate: MouseArea {
            required property var modelData
            readonly property int b: Tema.bordaRedimensionar
            readonly property bool horizontal: modelData.bordas & (Qt.LeftEdge | Qt.RightEdge)
            readonly property bool vertical: modelData.bordas & (Qt.TopEdge | Qt.BottomEdge)
            x: modelData.bordas & Qt.RightEdge ? bordas.width - b : 0
            y: modelData.bordas & Qt.BottomEdge ? bordas.height - b : 0
            width: horizontal ? b : bordas.width
            height: vertical ? b : bordas.height
            cursorShape: modelData.cursor
            onPressed: bordas.janelaAlvo.startSystemResize(modelData.bordas)
        }
    }
}
