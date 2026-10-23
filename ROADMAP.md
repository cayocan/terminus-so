# Roadmap

## Fase 1 — ISO base bootável
- [x] Configuração do live-build (Debian 13, live + instalador Calamares)
- [x] Hyprland pelos backports, drivers AMD (Mesa), PipeWire
- [x] Steam (i386), Wine, Flatpak (Bottles e ProtonUp-Qt no primeiro uso), KVM/QEMU
- [x] Quickshell compilado na build
- [x] Fontes Orbitron e Inter
- [x] Build automática no GitHub Actions
- [x] Primeira build bem-sucedida
- [x] Boot em VM (VirtualBox, UEFI): login automático, pt_BR e teclado ABNT2, Quickshell, Hyprland e fontes presentes
- [x] Hyprland em VM com o 3D do VirtualBox (funciona com Hyper-V/WSL2 ativo); esfera em VM com Qt Quick por software
- [x] Abrir o Hyprland e a esfera automaticamente após o login, com volta ao terminal se o Hyprland falhar
- [ ] Teste no PC de referência (Ryzen 7 1800X, RX 5500 XT)
- [x] Conferir a sintaxe de regras de janela da versão do Hyprland instalada (0.55, `--verify-config`)

## Fase 2 — Interface (Quickshell)
- [x] Esfera de energia com os 7 estados
- [x] Widgets: hora e data, hardware (CPU, GPU AMD, memória), notificações (servidor do sistema, Não perturbe)
- [ ] Linha de cidade e clima embaixo da data (precisa de um conector de clima)
- [x] Dock estilo macOS: lupa, indicador de app aberto, foca o app se já estiver aberto
- [ ] Dock: pastas em leque, atalhos de Pastas/Busca/Configurações/Downloads/Lixeira (dependem dessas telas)
- [x] Áreas de atalho: criar (clique direito no fundo), mover, redimensionar com alças, minimizar, renomear, excluir, adicionar e remover atalhos; salvas na camada pessoal
- [ ] Áreas de atalho por voz ("cria uma área de estudos", "minimiza a área de trabalho", "organiza as áreas"), depende do MCP (fase 3)
- [ ] Ícone escolhido por área (hoje todas minimizadas usam a maleta)
- [x] Busca global: apps e arquivos da pasta pessoal, ação "Mostrar na pasta", teclado (↑ ↓ Enter Esc), pela dock ou Super + Espaço
- [ ] Busca global: configurações e ações do assistente (dependem das telas de configuração e do MCP), busca por voz, nomes de arquivo sem acento casando com acentuados
- [x] Navegador de pastas: janela com barra de título própria (mover, redimensionar, minimizar, maximizar, fechar), histórico, caminho clicável, busca, modos ícones e lista, Favoritos/Locais/Áreas, espaço livre; abre pela dock (Pastas e Downloads)
- [x] Navegador de pastas: copiar, recortar e colar, renomear, nova pasta, mover para a Lixeira (menus e atalhos), seleção com Ctrl
- [x] Lixeira (padrão freedesktop): abre pela dock, restaurar e esvaziar com confirmação
- [ ] Navegador de pastas: arrastar e soltar, seleção com Shift, modo colunas, progresso de cópias grandes
- [ ] Minimizar janelas de outros apps (o Hyprland não tem minimizar; hoje só as janelas do Terminus escondem)
- [ ] Central de notificações
- [ ] Configurações e painel de conectores
- [ ] Presets de cor (Jarvis clássico, Mark, Stealth) e cores livres

## Fase 3 — MCP do sistema
- [ ] Servidor MCP local com os grupos de ferramentas da especificação
- [ ] Níveis de permissão (livre, confirmação por voz, senha)
- [ ] Histórico de ações

## Fase 4 — Assistente local
- [ ] llama.cpp com Vulkan e escolha do modelo (testar 2–3 de 7–8B em português)
- [ ] Whisper (whisper.cpp) para ouvir
- [ ] Piper para falar; XTTS v2 / F5-TTS opcional
- [ ] openWakeWord com palavra escolhida pelo usuário
- [ ] Manual do sistema para consulta do modelo

## Fase 5 — IAs de programação
- [ ] Conector do Claude Code (linha de comando, conta do usuário)
- [ ] Conectores de outras IAs
- [ ] Fluxo de aprovação de função nova

## Fase 6 — Conectores e bom dia
- [ ] Conectores de e-mail e Kanban
- [ ] Briefing do bom dia com o arco de pendências

## Fase 7 — Camadas e atualizações
- [ ] Separação camada base / camada pessoal
- [ ] Atualizador pelo GitHub com snapshot e resolução de conflitos
- [ ] Exportar para Git próprio e gerar ISO pessoal

## Fase 8 — Boot, login e onboarding
- [ ] Animação de boot
- [ ] Tela de login (senha + voz)
- [ ] Onboarding de 8 passos
