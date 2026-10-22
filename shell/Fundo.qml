import QtQuick
import QtQuick.Shapes
import "tema"

// Fundo da tela principal: grade do HUD, brilho azul atrás da esfera e dois anéis em volta dela.
Rectangle {
    id: fundo

    // Centro e raio da esfera, para alinhar o brilho e os anéis.
    property point centro: Qt.point(width / 2, height / 2)
    property real raioEsfera: 260

    color: Tema.fundo
    Accessible.ignored: true

    // A grade é estática: desenhada uma vez e só refeita quando a tela muda de tamanho.
    Canvas {
        anchors.fill: parent
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            ctx.strokeStyle = Tema.grade
            ctx.lineWidth = 1
            ctx.beginPath()
            for (let x = Tema.passoGrade; x < width; x += Tema.passoGrade) {
                ctx.moveTo(x + 0.5, 0)
                ctx.lineTo(x + 0.5, height)
            }
            for (let y = Tema.passoGrade; y < height; y += Tema.passoGrade) {
                ctx.moveTo(0, y + 0.5)
                ctx.lineTo(width, y + 0.5)
            }
            ctx.stroke()
        }
    }

    Shape {
        id: brilho
        anchors.fill: parent
        ShapePath {
            strokeColor: "transparent"
            fillGradient: RadialGradient {
                centerX: fundo.centro.x; centerY: fundo.centro.y
                focalX: centerX; focalY: centerY
                centerRadius: Math.max(fundo.width, fundo.height) * 0.45; focalRadius: 0
                GradientStop { position: 0.0; color: Qt.alpha(Tema.profunda, 0.22) }
                GradientStop { position: 0.6; color: Qt.alpha(Tema.profunda, 0.05) }
                GradientStop { position: 1.0; color: "transparent" }
            }
            PathRectangle { width: brilho.width; height: brilho.height }
        }
    }

    Rectangle {
        x: fundo.centro.x - width / 2
        y: fundo.centro.y - height / 2
        width: fundo.raioEsfera * 2 * 330 / 260
        height: width
        radius: width / 2
        color: "transparent"
        border.color: Qt.alpha(Tema.principal, 0.08)
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: Qt.alpha(Tema.principal, 0.05)
            strokeWidth: 1
            fillColor: "transparent"
            strokeStyle: ShapePath.DashLine
            dashPattern: [2, 14]
            PathAngleArc {
                centerX: fundo.centro.x; centerY: fundo.centro.y
                radiusX: fundo.raioEsfera * 420 / 260; radiusY: radiusX
                startAngle: 0; sweepAngle: 360
            }
        }
    }
}
