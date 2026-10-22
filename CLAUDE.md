# Terminus SO — contexto para o Claude Code

Sistema operacional Linux ultra leve, controlado por voz, com a esfera do assistente no centro da tela. O dono do projeto é o usuário (GitHub: cayocan); contribuições externas entram só por pull request aprovado por ele.

## Idioma
- Converse, comente o código e escreva commits em português do Brasil.

## Decisões fechadas
- Base: Debian 13 (Trixie), ISO via live-build; roda do pendrive (live) ou instalada (Calamares), em partição própria ao lado do Windows.
- Ambiente gráfico: Hyprland (backports do Trixie), janelas soltas com botões à direita estilo Windows. Sem área de trabalho com ícones: navegação por pastas, dock estilo macOS e áreas de atalho móveis.
- Interface: Quickshell (QML). Fontes Orbitron (títulos) e Inter (texto). Cores padrão: ciano #22D3EE e azul #1E6BFF sobre #04070D; presets Jarvis clássico, Mark e Stealth, mais cores livres.
- Esfera: de energia, sem núcleo sólido (filamentos de luz, partículas, ondas). Estados: repouso, escutando, pensando, falando, programando, atencao, erro.
- Compatibilidade: Steam + Proton/Proton-GE, Wine/Bottles, VM Windows (KVM + WinApps) de reserva. EA SPORTS FC não roda (anti-cheat Javelin); Rocket League roda.
- Assistente: 100% local. llama.cpp com Vulkan (modelo de 7–8B, a escolher testando em português), whisper.cpp, Piper como voz padrão e XTTS v2 / F5-TTS opcional, openWakeWord. Nome e palavra de ativação escolhidos por cada usuário no onboarding.
- Controle do sistema: tudo passa por um servidor MCP local. Cada ferramenta tem nível de permissão: livre, confirmação por voz ou senha. Histórico de todas as ações.
- IAs de programação: tarefas complexas vão para uma IA de programação pela linha de comando, sempre pela conta do usuário. NUNCA usar API paga. Padrão: Claude Code; outras IAs entram por conectores. Função nova criada pela IA vai para a camada pessoal; pedir senha para ativar é opção nas configurações.
- Camadas: a base vem deste repositório e se atualiza pelo GitHub sem reinstalar, com snapshot antes. A camada pessoal (~/.config/.../pessoal, pasta pessoal/) nunca é sobrescrita; conflitos são perguntados ao usuário. O usuário pode exportar o sistema para um Git próprio ou gerar uma ISO pessoal.
- Login: senha sempre no boot; voz basta na tela de bloqueio; ações sensíveis pedem senha.
- Onboarding obrigatório de 8 passos (idioma, nome e ativação, conta e voz, rede, visual, IA de programação, conectores, teste do bom dia); rede, IA e conectores aceitam "nenhum".

## PC de referência
Ryzen 7 1800X, 16 GB de RAM, Radeon RX 5500 XT 8 GB, Meta Quest 3 para testes de VR.

## Onde está cada coisa
- `iso/` build da ISO (live-build). `iso/build.sh` gera a ISO; o workflow `.github/workflows/build-iso.yml` gera no GitHub Actions.
- `shell/` interface em Quickshell. `preview/Preview.qml` mostra a esfera em qualquer PC com Qt 6 (`qml preview/Preview.qml`).
- `ROADMAP.md` fases e o que falta.
- `shell/tema/Tema.qml` singleton com todas as cores, fontes, raios e medidas do design (importar com `import "tema"`). Toda tela nova usa o Tema; nada de cores ou medidas soltas no código. Se faltar um valor, adicione-o ao Tema seguindo `docs/design/README.md`.
- `docs/design/` referências visuais: `README.md` tem cores, presets, tipografia, medidas e o índice das telas; `telas/*.dc.html` é o código-fonte de cada tela desenhada no Claude Design. Ao implementar uma tela em QML, abra o arquivo correspondente e use os valores dos estilos inline como fonte da verdade.

## Próximo passo
Primeira build da ISO e teste em VM (fase 1), depois widgets, dock e áreas de atalho (fase 2).
