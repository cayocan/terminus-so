import QtQuick
import QtQuick.Shapes

Shape {
    id: filamento

    property real escala: 1
    property real raio: 150
    property real amplitude: 10
    property int lobos: 5
    property real fase: 0
    property color cor: "#22D3EE"
    property real opacidadeTraco: 0.8
    property real espessura: 1.5
    property int duracaoGiro: 40000
    property int duracaoPulso: 6000
    property int sentido: 1
    property real intensidade: 1
    property bool rodando: true

    readonly property real centro: width / 2
    readonly property var pontos: gerarPontos(raio * escala, amplitude * escala * intensidade, lobos, fase, centro)

    function gerarPontos(r, amp, k, ph, c) {
        const lista = []
        const n = 96
        for (let i = 0; i <= n; i++) {
            const t = i / n * Math.PI * 2
            const d = r + amp * Math.sin(k * t + ph) + amp * 0.4 * Math.sin((k + 2) * t - ph * 1.3)
            lista.push(Qt.point(c + d * Math.cos(t), c + d * Math.sin(t)))
        }
        return lista
    }

    preferredRendererType: Shape.CurveRenderer
    antialiasing: true
    Accessible.ignored: true

    ShapePath {
        strokeColor: Qt.alpha(filamento.cor, filamento.opacidadeTraco)
        strokeWidth: filamento.espessura * filamento.escala
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap
        joinStyle: ShapePath.RoundJoin
        PathPolyline { path: filamento.pontos }
    }

    RotationAnimator on rotation {
        id: giro
        from: filamento.sentido > 0 ? 0 : 360
        to: filamento.sentido > 0 ? 360 : 0
        duration: filamento.duracaoGiro
        loops: Animation.Infinite
        running: filamento.rodando
    }

    SequentialAnimation on scale {
        id: pulso
        loops: Animation.Infinite
        running: filamento.rodando
        ScaleAnimator { from: 1; to: 1 + 0.03 * filamento.intensidade; duration: filamento.duracaoPulso / 2; easing.type: Easing.InOutSine }
        ScaleAnimator { from: 1 + 0.03 * filamento.intensidade; to: 1; duration: filamento.duracaoPulso / 2; easing.type: Easing.InOutSine }
    }

    onDuracaoGiroChanged: if (giro.running) giro.restart()
    onDuracaoPulsoChanged: if (pulso.running) pulso.restart()
}
