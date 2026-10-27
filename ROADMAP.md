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
- [x] Dock: atalhos de Pastas, Busca, Configurações, Downloads e Lixeira; Downloads abre em leque com os arquivos mais recentes
- [ ] Dock: fixar e tirar apps, escolher outras pastas em leque
- [x] Áreas de atalho: criar (clique direito no fundo), mover, redimensionar com alças, minimizar, renomear, excluir, adicionar e remover atalhos; salvas na camada pessoal
- [ ] Áreas de atalho por voz ("cria uma área de estudos", "minimiza a área de trabalho", "organiza as áreas"), depende do MCP (fase 3)
- [x] Ícone escolhido por área (Trocar ícone) e confirmação antes de excluir uma área
- [x] Busca global: apps e arquivos da pasta pessoal, ação "Mostrar na pasta", teclado (↑ ↓ Enter Esc), pela dock ou Super + Espaço
- [ ] Busca global: configurações e ações do assistente (dependem das telas de configuração e do MCP), busca por voz, nomes de arquivo sem acento casando com acentuados
- [x] Navegador de pastas: janela com barra de título própria (mover, redimensionar, minimizar, maximizar, fechar), histórico, caminho clicável, busca, modos ícones e lista, Favoritos/Locais/Áreas, espaço livre; abre pela dock (Pastas e Downloads)
- [x] Navegador de pastas: copiar, recortar e colar, renomear, nova pasta, mover para a Lixeira (menus e atalhos), seleção com Ctrl
- [x] Lixeira (padrão freedesktop): abre pela dock, restaurar e esvaziar com confirmação
- [ ] Navegador de pastas: arrastar e soltar, seleção com Shift, modo colunas, progresso de cópias grandes
- [ ] Minimizar janelas de outros apps (o Hyprland não tem minimizar; hoje só as janelas do Terminus escondem)
- [x] Central de notificações: histórico de 7 dias agrupado por dia, Limpar, Não perturbe, aviso flutuante (urgentes passam pelo Não perturbe), Super + N
- [x] "O que eu perdi?": resumo em texto das não lidas sob a esfera, que fica em "falando"
- [ ] "O que eu perdi?" falado (Piper) e por voz; resumo escrito pelo modelo local em vez do texto fixo
- [ ] Ações das notificações (botões), lembrar o Não perturbe entre reinícios
- [x] Configurações: janela com as 11 categorias e busca; Aparência, Esfera e assistente (nome) e Conectores funcionam; as outras dizem o que vão ter
- [x] Painel de conectores (visual): estado, "Entra no bom dia" salvo; conectar e criar conector chegam nas fases 6 e 5
- [x] Presets de cor (Jarvis clássico, Mark, Stealth), salvos na camada pessoal e aplicados na hora
- [ ] Cores livres; borda das janelas do Hyprland seguir o preset (hoje fica ciano)
- [ ] Páginas de Rede, Som, Telas, Áreas e dock e Jogos

## Fase 3 — MCP do sistema
- [x] Servidor MCP local (Python, sem dependências) com 24 ferramentas em 9 grupos (lista em `mcp/README.md`)
- [x] Níveis de permissão (livre, confirmação, senha conferida pelo PAM), ajustáveis em Configurações → Usuários e segurança
- [x] Histórico de ações, na mesma página
- [ ] Confirmação por voz (depende do assistente, fase 4)
- [ ] Ferramentas de rede, telas, apps (instalar/remover), atualizações e jogos, junto com as páginas de cada um

## Fase 4 — Assistente local
- [x] Escolha do modelo: Qwen3 8B Q4_K_M, testado na RX 5500 XT com llama.cpp Vulkan (24 tokens/s, 10/10 nas ferramentas do MCP; detalhes em `assistente/README.md`)
- [x] llama.cpp com Vulkan na ISO (binário oficial b11838) e download do modelo no primeiro uso, pela caixa de conversa (Qwen3 8B com placa de 6 GB+, Qwen3 1.7B sem)
- [x] Laço do assistente: modelo ↔ ferramentas do MCP, com confirmações e senha na tela, aquecimento do cache ao subir; 3 a 6 s por pergunta na RX 5500 XT
- [x] Conversa digitada: clique na esfera ou Super + A; esfera pensando/falando e resposta embaixo dela
- [ ] Testar o assistente no PC de referência com a ISO (até agora: laço com a GPU do host e fluxo completo na VM, no processador)
- [ ] Respostas sem oferecer o que as ferramentas não fazem (o 8B às vezes termina com "Deseja instalar?")
- [x] Whisper (whisper.cpp, modelo small) para ouvir, com fim da fala por silêncio; escuta ao abrir a conversa
- [x] Piper para falar (voz cadu), direto no PipeWire; respostas só escritas como opção
- [ ] whisper.cpp na placa de vídeo (Vulkan): hoje 4,5 s por frase no processador
- [ ] Testar microfone e alto-falante de verdade no PC de referência
- [ ] Escolher a voz no onboarding e nas Configurações; XTTS v2 / F5-TTS opcional
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
