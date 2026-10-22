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
- [ ] Hyprland em VM: precisa de aceleração 3D, que o VirtualBox não tem com o Hyper-V/WSL2 ativo no Windows
- [ ] Abrir o Hyprland e a esfera automaticamente após o login (hoje cai no terminal)
- [ ] Teste no PC de referência (Ryzen 7 1800X, RX 5500 XT)
- [ ] Conferir a sintaxe de regras de janela da versão do Hyprland instalada

## Fase 2 — Interface (Quickshell)
- [x] Esfera de energia com os 7 estados
- [ ] Widgets: hora e data, hardware, notificações
- [ ] Dock estilo macOS com pastas em leque
- [ ] Áreas de atalho (criar, mover, redimensionar, minimizar)
- [ ] Busca global
- [ ] Navegador de pastas
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
