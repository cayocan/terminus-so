import QtQuick
import QtQuick.Shapes
import QtQuick.Particles
import QtQuick.Effects

Item {
    id: esfera

    property string estado: "repouso"
    property color corPrincipal: "#22D3EE"
    property color corProfunda: "#1E6BFF"
    property bool animando: visible

    implicitWidth: 520
    implicitHeight: 520

    readonly property var perfis: ({
        repouso:     { amp: 0.55, giro: 1.6,  pulso: 1.8,  brilho: 0.70, ondas: 7000, particulas: 18, anel: false },
        escutando:   { amp: 1.5,  giro: 0.8,  pulso: 0.3,  brilho: 1.00, ondas: 1600, particulas: 40, anel: false },
        pensando:    { amp: 1.0,  giro: 0.15, pulso: 0.8,  brilho: 0.90, ondas: 5000, particulas: 60, anel: false },
        falando:     { amp: 1.8,  giro: 0.6,  pulso: 0.18, brilho: 1.00, ondas: 2400, particulas: 45, anel: false },
        programando: { amp: 0.9,  giro: 0.4,  pulso: 0.9,  brilho: 0.85, ondas: 6000, particulas: 35, anel: true },
        atencao:     { amp: 1.2,  giro: 1.0,  pulso: 0.5,  brilho: 0.95, ondas: 2200, particulas: 35, anel: false, a: "#F5A54A", d: "#C2611F" },
        erro:        { amp: 1.6,  giro: 0.9,  pulso: 0.25, brilho: 1.00, ondas: 1200, particulas: 40, anel: false, a: "#F05252", d: "#A42828" }
    })
    readonly property var perfil: perfis[estado] !== undefined ? perfis[estado] : perfis.repouso
    readonly property color corA: perfil.a !== undefined ? perfil.a : corPrincipal
    readonly property color corD: perfil.d !== undefined ? perfil.d : corProfunda
    readonly property real escala: Math.min(width, height) / 520

    // [raio, amplitude, lobos, fase, cor, opacidade, espessura, giro (ms), pulso (ms), sentido]
    readonly property var especificacoes: [
        [150, 10, 5, 0.0, "a", 0.90, 1.6, 40000, 6000,  1],
        [146, 14, 3, 1.0, "d", 0.85, 2.2, 55000, 8000, -1],
        [156,  8, 7, 2.0, "w", 0.45, 1.0, 30000, 5000,  1],
        [138, 12, 4, 3.0, "a", 0.60, 1.2, 70000, 9000, -1],
        [162,  6, 6, 4.0, "d", 0.55, 1.0, 45000, 7000,  1],
        [130, 16, 5, 5.0, "a", 0.40, 1.0, 35000, 10000, -1],
        [120, 10, 3, 0.5, "w", 0.30, 0.8, 80000, 6500,  1],
        [105, 12, 6, 2.5, "a", 0.35, 1.0, 25000, 5500, -1],
        [ 90, 14, 4, 1.5, "d", 0.30, 1.0, 50000, 8500,  1]
    ]

    Accessible.role: Accessible.Animation
    Accessible.name: qsTr("Esfera do assistente")

    Shape {
        id: halo
        anchors.fill: parent
        Accessible.ignored: true
        ShapePath {
            strokeColor: "transparent"
            fillGradient: RadialGradient {
                centerX: halo.width / 2; centerY: halo.height / 2
                focalX: centerX; focalY: centerY
                centerRadius: halo.width / 2; focalRadius: 0
                GradientStop { position: 0.0; color: Qt.alpha(esfera.corA, 0.16) }
                GradientStop { position: 0.45; color: Qt.alpha(esfera.corD, 0.07) }
                GradientStop { position: 1.0; color: "transparent" }
            }
            PathAngleArc {
                centerX: halo.width / 2; centerY: halo.height / 2
                radiusX: halo.width / 2; radiusY: halo.height / 2
                startAngle: 0; sweepAngle: 360
            }
        }
    }

    Repeater {
        model: 2
        delegate: Rectangle {
            id: onda
            required property int index
            anchors.centerIn: parent
            width: 300 * esfera.escala
            height: width
            radius: width / 2
            color: "transparent"
            border.color: esfera.corA
            border.width: 1
            opacity: 0
            Accessible.ignored: true

            SequentialAnimation {
                running: esfera.animando
                loops: Animation.Infinite
                PauseAnimation { duration: onda.index * esfera.perfil.ondas / 2 }
                ParallelAnimation {
                    ScaleAnimator { target: onda; from: 1; to: 1.63; duration: esfera.perfil.ondas }
                    OpacityAnimator { target: onda; from: 0.45; to: 0; duration: esfera.perfil.ondas }
                }
            }
        }
    }

    Shape {
        id: coracao
        anchors.centerIn: parent
        width: 180 * esfera.escala
        height: width
        Accessible.ignored: true
        ShapePath {
            strokeColor: "transparent"
            fillGradient: RadialGradient {
                centerX: coracao.width / 2; centerY: coracao.height / 2
                focalX: centerX; focalY: centerY
                centerRadius: coracao.width / 2; focalRadius: 0
                GradientStop { position: 0.0; color: Qt.alpha(esfera.corA, 0.6 * esfera.perfil.brilho) }
                GradientStop { position: 0.6; color: Qt.alpha(esfera.corD, 0.15) }
                GradientStop { position: 1.0; color: "transparent" }
            }
            PathAngleArc {
                centerX: coracao.width / 2; centerY: coracao.height / 2
                radiusX: coracao.width / 2; radiusY: coracao.height / 2
                startAngle: 0; sweepAngle: 360
            }
        }
        SequentialAnimation on scale {
            running: esfera.animando
            loops: Animation.Infinite
            ScaleAnimator { from: 0.85; to: 1.1; duration: 2500 * esfera.perfil.pulso + 400; easing.type: Easing.InOutSine }
            ScaleAnimator { from: 1.1; to: 0.85; duration: 2500 * esfera.perfil.pulso + 400; easing.type: Easing.InOutSine }
        }
    }

    Item {
        id: filamentos
        anchors.fill: parent
        layer.enabled: true
        Accessible.ignored: true

        Repeater {
            model: esfera.especificacoes
            delegate: Filamento {
                required property var modelData
                anchors.fill: parent
                escala: esfera.escala
                raio: modelData[0]
                amplitude: modelData[1]
                lobos: modelData[2]
                fase: modelData[3]
                cor: modelData[4] === "a" ? esfera.corA : (modelData[4] === "d" ? esfera.corD : "#EAF8FF")
                opacidadeTraco: Math.min(1, modelData[5] * esfera.perfil.brilho)
                espessura: modelData[6]
                duracaoGiro: modelData[7] * esfera.perfil.giro
                duracaoPulso: modelData[8] * esfera.perfil.pulso
                sentido: modelData[9]
                intensidade: esfera.perfil.amp
                rodando: esfera.animando
            }
        }

        Shape {
            id: anel
            anchors.fill: parent
            visible: esfera.perfil.anel
            ShapePath {
                strokeColor: "#22D3EE"
                strokeWidth: 2 * esfera.escala
                strokeStyle: ShapePath.DashLine
                dashPattern: [3, 7]
                fillColor: "transparent"
                PathAngleArc {
                    centerX: anel.width / 2; centerY: anel.height / 2
                    radiusX: 215 * esfera.escala; radiusY: radiusX
                    startAngle: 0; sweepAngle: 360
                }
            }
            RotationAnimator on rotation {
                from: 360; to: 0; duration: 8000
                loops: Animation.Infinite
                running: esfera.animando && anel.visible
            }
        }
    }

    MultiEffect {
        source: filamentos
        anchors.fill: filamentos
        blurEnabled: true
        blurMax: 24
        blur: 0.5
        brightness: 0.15
        Accessible.ignored: true
    }

    ParticleSystem {
        id: sistema
        anchors.fill: parent
        running: esfera.animando

        ImageParticle {
            groups: ["centelhas"]
            source: "qrc:///particleresources/glowdot.png"
            color: esfera.corA
            colorVariation: 0.15
            alpha: 0.8
            alphaVariation: 0.4
            entryEffect: ImageParticle.Fade
        }

        Emitter {
            group: "centelhas"
            anchors.centerIn: parent
            width: 300 * esfera.escala
            height: width
            shape: EllipseShape { fill: false }
            emitRate: esfera.perfil.particulas
            lifeSpan: 2600
            lifeSpanVariation: 900
            size: 7 * esfera.escala
            sizeVariation: 4 * esfera.escala
            velocity: AngleDirection {
                angleVariation: 360
                magnitude: 18 * esfera.escala
                magnitudeVariation: 14 * esfera.escala
            }
        }
    }

    Rectangle {
        anchors.centerIn: parent
        width: 10 * esfera.escala
        height: width
        radius: width / 2
        color: "#FFFFFF"
        opacity: 0.85 * esfera.perfil.brilho
        Accessible.ignored: true
    }
}
