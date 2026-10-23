import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import "tema"

// Uma área de atalhos na tela principal. Arrastar pelo título move; o botão de redimensionar mostra
// alças nos cantos, um contorno tracejado com a nova medida e aplica ao soltar; minimizar vira um círculo.
Item {
    id: area

    required property var dados
    required property Areas areas
    required property MenuContexto menu
    // Espaço livre para as áreas (a tela menos a faixa da dock).
    property size limites
    property bool redimensionando: false

    signal redimensionarAlternado()

    readonly property int colunas: Math.max(1, Math.floor((dados.largura - 2 * Tema.preenchimentoAreaH + Tema.espacoAtalhos)
                                                          / (Tema.iconeAtalho + 20 + Tema.espacoAtalhos)))
    // Medida em andamento ao arrastar uma alça: { x, y, largura, altura } relativo à área.
    property var fantasma: null

    readonly property string contagem: dados.atalhos.length === 1 ? qsTr("1 atalho")
                                                                  : qsTr("%1 atalhos").arg(dados.atalhos.length)

    function encaixar(v) { return Math.round(v / Tema.passoEncaixe) * Tema.passoEncaixe }

    function limitar(x, y, largura, altura) {
        largura = Math.max(Tema.larguraMinimaArea, Math.min(largura, limites.width))
        altura = Math.max(Tema.alturaMinimaArea, Math.min(altura, limites.height))
        return {
            x: Math.max(0, Math.min(encaixar(x), limites.width - largura)),
            y: Math.max(0, Math.min(encaixar(y), limites.height - altura)),
            largura: encaixar(largura), altura: encaixar(altura)
        }
    }

    function abrirMenu(item, px, py) {
        const p = item.mapToItem(menu, px, py)
        const itens = dados.minimizada ? [
            { texto: qsTr("Abrir área"), acao: () => areas.atualizar(dados.id, { minimizada: false }) },
            { texto: qsTr("Renomear"), acao: () => areas.dialogo = { tipo: "renomear", areaId: dados.id } },
            { texto: qsTr("Excluir área"), perigo: true, acao: () => areas.excluir(dados.id) }
        ] : [
            { texto: qsTr("Adicionar atalho"), acao: () => areas.dialogo = { tipo: "atalho", areaId: dados.id } },
            { texto: qsTr("Renomear"), acao: () => areas.dialogo = { tipo: "renomear", areaId: dados.id } },
            { texto: qsTr("Minimizar"), acao: () => areas.atualizar(dados.id, { minimizada: true }) },
            { texto: qsTr("Excluir área"), perigo: true, acao: () => areas.excluir(dados.id) }
        ]
        menu.abrir(p.x, p.y, itens)
    }

    function moverPara(x, y) {
        const l = limitar(x, y, dados.largura, dados.altura)
        areas.atualizar(dados.id, { x: l.x, y: l.y })
    }

    // Presa dentro da tela, caso a resolução tenha diminuído desde que a área foi salva.
    x: Math.max(0, Math.min(dados.x, limites.width - width))
    y: Math.max(0, Math.min(dados.y, limites.height - height))
    width: dados.minimizada ? minimizada.implicitWidth : dados.largura
    height: dados.minimizada ? minimizada.implicitHeight : dados.altura

    // ---------- Aberta ----------
    Rectangle {
        id: painel
        visible: !area.dados.minimizada
        anchors.fill: parent
        radius: Tema.raioArea
        color: area.redimensionando ? Tema.vidroPainel : Tema.vidroArea
        border.color: area.redimensionando ? Tema.principal : Tema.bordaDestaque
        border.width: area.redimensionando ? 1.5 : 1
        clip: true
        Accessible.role: Accessible.Grouping
        Accessible.name: qsTr("Área de atalhos %1").arg(area.dados.nome)

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.RightButton
            onClicked: mouse => area.abrirMenu(painel, mouse.x, mouse.y)
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: Tema.preenchimentoAreaH
            anchors.rightMargin: Tema.preenchimentoAreaH
            anchors.topMargin: Tema.preenchimentoAreaV - 6
            anchors.bottomMargin: Tema.preenchimentoAreaV
            spacing: 16

            RowLayout {
                id: cabecalho
                Layout.fillWidth: true

                Text {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: area.dados.nome.toUpperCase()
                    color: Tema.principal
                    font.family: Tema.fonteTitulo
                    font.weight: Font.DemiBold
                    font.pixelSize: Tema.tamanhoSecao
                    font.letterSpacing: Tema.espacamentoSecao

                    // Arrastar pelo título move a área.
                    DragHandler {
                        id: arrasto
                        target: area
                        enabled: !area.redimensionando
                        cursorShape: Qt.SizeAllCursor
                        onActiveChanged: if (!active) area.moverPara(area.x, area.y)
                    }
                }
                Text {
                    visible: area.redimensionando
                    text: area.contagem
                    color: Tema.textoDiscreto
                    font.family: Tema.fonteTexto
                    font.pixelSize: Tema.tamanhoLegenda
                }
                BotaoIcone {
                    nome: qsTr("Redimensionar área")
                    icone: Icones.expandir
                    marcado: area.redimensionando
                    onAcionado: area.redimensionarAlternado()
                }
                BotaoIcone {
                    nome: qsTr("Minimizar área")
                    icone: Icones.minimizar
                    onAcionado: area.areas.atualizar(area.dados.id, { minimizada: true })
                }
            }

            Grid {
                id: grade
                Layout.fillWidth: true
                columns: area.colunas
                spacing: Tema.espacoAtalhos
                readonly property real celula: (width - (columns - 1) * spacing) / columns

                Repeater {
                    model: area.dados.atalhos
                    delegate: AtalhoArea {
                        required property string modelData
                        width: grade.celula
                        entradaId: modelData
                        onMenuPedido: (mx, my) => {
                            const p = mapToItem(area.menu, mx, my)
                            area.menu.abrir(p.x, p.y, [
                                { texto: qsTr("Abrir"), acao: () => entrada && entrada.execute() },
                                { texto: qsTr("Remover da área"), perigo: true, acao: () => area.areas.removerAtalho(area.dados.id, modelData) }
                            ])
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                visible: area.dados.atalhos.length === 0
                text: qsTr("Área vazia. Clique com o botão direito para adicionar atalhos.")
                wrapMode: Text.Wrap
                color: Tema.textoDiscreto
                font.family: Tema.fonteTexto
                font.pixelSize: Tema.tamanhoTextoMenor
            }

            Item { Layout.fillHeight: true }
        }
    }

    // Alças de redimensionar nos quatro cantos.
    Repeater {
        model: area.redimensionando && !area.dados.minimizada ? ["se", "so", "ne", "no"] : []
        delegate: Rectangle {
            id: alca
            required property string modelData
            readonly property bool direita: modelData.endsWith("e")
            readonly property bool baixo: modelData.startsWith("s")

            x: (direita ? area.width : 0) - width / 2
            y: (baixo ? area.height : 0) - height / 2
            width: Tema.alcaArea
            height: Tema.alcaArea
            radius: Tema.raioAlca
            color: puxar.active ? Tema.principal : Tema.fundo
            border.color: Tema.principal
            border.width: 2
            Accessible.ignored: true

            DragHandler {
                id: puxar
                target: null
                cursorShape: (alca.direita === alca.baixo) ? Qt.SizeFDiagCursor : Qt.SizeBDiagCursor
                // Deslocamento medido desde onde o botão foi apertado, e não desde a ativação do arraste:
                // com poucos eventos de movimento (máquina ocupada), activeTranslation ficaria em zero.
                function medir() {
                    const dx = centroid.scenePosition.x - centroid.scenePressPosition.x
                    const dy = centroid.scenePosition.y - centroid.scenePressPosition.y
                    area.fantasma = {
                        x: alca.direita ? 0 : dx,
                        y: alca.baixo ? 0 : dy,
                        largura: area.dados.largura + (alca.direita ? dx : -dx),
                        altura: area.dados.altura + (alca.baixo ? dy : -dy)
                    }
                }
                onCentroidChanged: if (active) medir()
                onActiveChanged: {
                    if (active) { medir(); return }
                    if (area.fantasma === null) return
                    const f = area.fantasma
                    const l = area.limitar(area.x + f.x, area.y + f.y, f.largura, f.altura)
                    area.fantasma = null
                    area.areas.atualizar(area.dados.id, { x: l.x, y: l.y, largura: l.largura, altura: l.altura })
                }
            }
        }
    }

    // Contorno tracejado da nova medida, com a etiqueta "largura × altura".
    Shape {
        visible: area.fantasma !== null
        x: area.fantasma ? area.fantasma.x : 0
        y: area.fantasma ? area.fantasma.y : 0
        width: area.fantasma ? Math.max(1, area.fantasma.largura) : 1
        height: area.fantasma ? Math.max(1, area.fantasma.altura) : 1
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: Tema.bordaTracejada
            strokeWidth: 1.5
            strokeStyle: ShapePath.DashLine
            dashPattern: [4, 4]
            fillColor: "transparent"
            PathRectangle {
                width: area.fantasma ? Math.max(1, area.fantasma.largura) : 1
                height: area.fantasma ? Math.max(1, area.fantasma.altura) : 1
                radius: Tema.raioArea + 2
            }
        }

        Rectangle {
            anchors.top: parent.bottom
            anchors.topMargin: 12
            width: medida.implicitWidth + 24
            height: 32
            radius: 10
            color: Tema.etiquetaMedida

            Text {
                id: medida
                anchors.centerIn: parent
                text: area.fantasma ? "%1 × %2".arg(area.encaixar(Math.max(Tema.larguraMinimaArea, area.fantasma.largura)))
                                                .arg(area.encaixar(Math.max(Tema.alturaMinimaArea, area.fantasma.altura))) : ""
                color: Tema.principalClaro
                font.family: Tema.fonteTitulo
                font.pixelSize: Tema.tamanhoRotulo
            }
        }
    }

    // ---------- Minimizada ----------
    Row {
        id: minimizada
        visible: area.dados.minimizada
        spacing: 14

        Rectangle {
            id: circulo
            width: Tema.areaMinimizada
            height: Tema.areaMinimizada
            radius: width / 2
            color: toqueCirculo.hovered ? Qt.tint(Tema.vidroPainel, Tema.hover) : Tema.vidroPainel
            border.color: Tema.bordaDestaque
            activeFocusOnTab: true
            Accessible.role: Accessible.Button
            Accessible.name: qsTr("Abrir área %1").arg(area.dados.nome)
            Keys.onReturnPressed: area.areas.atualizar(area.dados.id, { minimizada: false })

            // Brilho interno do círculo (box-shadow inset do design).
            Rectangle {
                anchors.fill: parent
                anchors.margins: 6
                radius: width / 2
                color: Tema.destaqueSuave
                opacity: 0.6
            }
            Icone {
                anchors.centerIn: parent
                caminhos: Icones.maleta
                tamanho: 28
                cor: Tema.principal
            }

            HoverHandler { id: toqueCirculo; cursorShape: Qt.PointingHandCursor }
            TapHandler {
                acceptedButtons: Qt.LeftButton
                onTapped: area.areas.atualizar(area.dados.id, { minimizada: false })
            }
            TapHandler {
                acceptedButtons: Qt.RightButton
                onTapped: (ponto) => area.abrirMenu(circulo, ponto.position.x, ponto.position.y)
            }
            DragHandler {
                target: area
                onActiveChanged: if (!active) area.moverPara(area.x, area.y)
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            Text {
                text: area.dados.nome
                color: Tema.texto
                font.family: Tema.fonteTexto
                font.weight: Font.DemiBold
                font.pixelSize: Tema.tamanhoTexto
            }
            Text {
                text: qsTr("área minimizada · %1").arg(area.contagem)
                color: Tema.textoDiscreto
                font.family: Tema.fonteTexto
                font.pixelSize: Tema.tamanhoRotulo
            }
        }
    }
}
