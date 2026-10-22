# Terminus SO

Sistema operacional Linux ultra leve, controlado por voz, com a esfera do assistente no centro da tela e alta compatibilidade com programas e jogos do Windows.

- Base: Debian 13 (Trixie), instalável ou rodando direto do pendrive
- Ambiente gráfico: Hyprland (Wayland) com a interface desenhada em Quickshell (QML)
- Compatibilidade: Steam + Proton, Wine/Bottles e VM Windows (KVM) de reserva
- Assistente: modelo local (llama.cpp), Whisper e Piper, controlando o sistema por um servidor MCP
- IA de programação: Claude Code por padrão (pela conta do usuário, sem API), ou outra IA à escolha

As decisões completas estão na especificação técnica e na especificação de design do projeto.

## Estrutura

```
terminus-so/
├── iso/                 Build da ISO com live-build (fase 1)
│   ├── build.sh         Gera a ISO
│   ├── auto/config      Parâmetros do live-build
│   └── config/          Pacotes, hooks, repositórios e arquivos do sistema
├── shell/               Interface do sistema em Quickshell (QML)
│   ├── shell.qml        Ponto de entrada do Quickshell
│   ├── TelaPrincipal.qml
│   ├── Esfera.qml       A esfera de energia e seus estados
│   └── Filamento.qml    Um filamento de luz da esfera
├── preview/             Visualizar componentes fora do sistema
│   └── Preview.qml
├── mcp/                 Servidor MCP do sistema (fase 3)
├── assistente/          Assistente local: voz, modelo e palavra de ativação (fase 4)
├── ia-programacao/      Conectores para Claude Code e outras IAs (fase 5)
├── conectores/          Conectores de serviços e briefing do bom dia (fase 6)
├── atualizador/         Camadas base/pessoal e atualização pelo GitHub (fase 7)
└── .github/workflows/   Build automática da ISO no GitHub Actions
```

## Gerar a ISO

A forma mais simples é pelo GitHub: a cada push na branch `main`, o workflow `build-iso` gera a ISO e deixa para download na aba **Actions**.

Para gerar localmente, num Debian 13 (ou num container Debian 13 com privilégios):

```bash
sudo apt install live-build
cd iso
sudo ./build.sh
```

A ISO sai em `iso/terminus-so-amd64.hybrid.iso`. Grave num pendrive com o balenaEtcher ou o Ventoy, ou teste numa máquina virtual.

## Ver a esfera sem instalar o sistema

Com o Qt 6 instalado (Linux ou Windows), rode:

```bash
qml preview/Preview.qml
```

Dá para trocar o estado da esfera e o preset de cores pela própria janela.

## Contribuições

O projeto aceita contribuições por pull request; todas passam pela aprovação do dono do projeto. Mudanças pessoais de cada usuário ficam na camada pessoal e não entram aqui.
