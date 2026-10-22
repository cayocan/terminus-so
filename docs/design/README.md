# Design do Terminus SO

Todas as telas foram desenhadas no Claude Design (canvas "Terminus SO — Telas"). Os arquivos em `telas/` são o código-fonte dessas telas: HTML com estilos inline, onde cada medida, cor e espaçamento está escrito literalmente. Eles não abrem sozinhos no navegador (dependem do runtime do Claude Design), mas servem de referência exata para implementar em QML: os valores dos atributos `style` são a fonte da verdade.

Telas desenhadas em 1920 × 1080, salvo os componentes.

## Telas

| Arquivo | Tela | Fase |
| --- | --- | --- |
| `Main.dc.html` | Tela principal: esfera, hora e data, hardware, notificações, área de atalhos, área minimizada e dock | 2 |
| `Esfera.dc.html` | Componente da esfera de energia (estado, preset e tamanho) | 2 |
| `Estados.dc.html` | Os 7 estados da esfera lado a lado | 2 |
| `AreasDock.dc.html` | Área sendo redimensionada, áreas minimizadas, pasta em leque na dock, efeito de lupa | 2 |
| `Pastas.dc.html` | Navegador de pastas estilo Finder, janela com botões à direita | 2 |
| `Busca.dc.html` | Busca global com resultados agrupados | 2 |
| `Notificacoes.dc.html` | Central de notificações e "O que eu perdi?" | 2 |
| `Config.dc.html` | Configurações e painel de conectores | 2 e 6 |
| `FuncaoNova.dc.html` | Aprovação de função criada pela IA de programação | 5 |
| `BomDia.dc.html` | Briefing do bom dia com o arco de pendências | 6 |
| `Atualizacao.dc.html` | Atualização da base com conflitos | 7 |
| `Boot.dc.html` | Animação de boot | 8 |
| `Login.dc.html` | Tela de login | 8 |
| `OnbRail.dc.html` | Componente: trilha de etapas do onboarding | 8 |
| `OnbIdioma.dc.html` … `OnbTeste.dc.html` | Os 8 passos do onboarding | 8 |

## Cores

| Uso | Cor |
| --- | --- |
| Fundo | `#04070D` |
| Destaque principal (ciano) | `#22D3EE` |
| Azul profundo | `#1E6BFF` |
| Texto principal | `#E6F4FB` / `#EAF6FC` / `#F2FAFF` (títulos) |
| Texto secundário | `#CFE6F2`, `#B8D2E2`, `#A9C7DA` |
| Texto discreto (rótulos, horários) | `#8FB3CC` |
| Ciano claro (estados ativos) | `#7FE3F3` |
| Links | `#7FD8EA`, hover `#B9EEF7` |
| Atenção | `#F5A54A` (texto `#F8C27F`) |
| Erro | `#F05252` / `#F87171` (texto `#FCA5A5`) |
| Sucesso | `#34D399` (texto `#6EE7B7`) |
| Programando (IA) | `#3B82F6` / `#9CC0FA` |
| Grade do fundo | `#9CC9E0` a 4,5% |

Presets da esfera e dos destaques:

| Preset | Principal | Profunda |
| --- | --- | --- |
| Jarvis clássico (padrão) | `#22D3EE` | `#1E6BFF` |
| Mark | `#F5B83D` | `#E5484D` |
| Stealth | `#D6DEE6` | `#6B7A8C` |

## Material de vidro

- Painéis: fundo `rgba(10,22,38,0.55–0.72)`, borda 1px `rgba(34,211,238,0.28)` (ou `rgba(156,201,224,0.16)` em painéis neutros).
- Janelas: fundo `rgba(9,18,32,0.94–0.97)`, borda `rgba(34,211,238,0.3)`, sombra `0 30px 80px rgba(0,0,0,0.55)`, raio 18px.
- Item selecionado: fundo `rgba(34,211,238,0.10–0.14)`, borda 1,5–2px `#22D3EE`.
- Fundo da tela: grade de 48px com linhas `#9CC9E0` a 4,5% e um brilho radial azul `#1E6BFF` a ~20% atrás da esfera.

## Tipografia

- Títulos, hora, rótulos em caixa alta: **Orbitron** 600, com espaçamento entre letras de 2–8px.
- Texto: **Inter** 400/500/600.
- Tamanhos usados: hora 84–112px; títulos de tela 38–42px; títulos de seção 13px em caixa alta com espaçamento de 1,5–4px; texto 14–18px; legendas 12–13px.

## Medidas

- Raios: cartões 16–22px, botões em pílula 22–26px, ícones 12–18px.
- Alvos de toque: mínimo 44px.
- Dock: altura 80–92px, ícones 56–60px, raio 26–28px, a 28px da borda inferior.
- Margens laterais da tela principal: 64px.

## Esfera

A esfera não tem núcleo sólido: 9 filamentos de luz ondulados (raios de 90 a 162 numa base de 520px), girando e pulsando em ritmos e sentidos diferentes, partículas em dois enxames, brilho difuso no centro, um ponto de luz central e duas ondas que se expandem. Os parâmetros de cada estado estão em `Esfera.dc.html` (função `renderVals`) e já foram portados para `shell/Esfera.qml`.

## Especificações

As duas especificações completas (técnica e de design) estão em documentos do Claude. Para trazê-las ao projeto, abra cada documento, exporte em Markdown e salve em `docs/`.
