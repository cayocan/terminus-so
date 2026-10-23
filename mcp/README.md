# MCP do sistema

Servidor MCP local que expõe as funções do sistema como ferramentas, cada uma com um nível de permissão (livre, confirmação ou senha), e registra todas as ações num histórico. É por ele que o assistente local e as IAs de programação mexem no Terminus SO. Fase 3 do roadmap.

Python 3 puro, sem dependências: roda com o `python3` do Debian.

## Como funciona

```
assistente / IA de programação ──(stdio)──► terminus-mcp stdio ─┐
                                                                 ├─► mcp.sock ─► servidor ─► ferramentas
outro cliente MCP ───────────────────────────────────────────────┘                  │
                                                                                      ▼
                          shell (Quickshell) ◄──── interface.sock ──── confirmações, comandos de tela, histórico
```

- **Servidor** (`terminus-mcp servidor`): serviço de usuário do systemd (`terminus-mcp.service`), iniciado pelo Hyprland no login. Fala JSON-RPC 2.0 do MCP, uma mensagem por linha, no socket `$XDG_RUNTIME_DIR/terminus/mcp.sock` (permissão 600, só o próprio usuário).
- **Ponte stdio** (`terminus-mcp stdio`): para clientes MCP que só falam por stdio. Repassa tudo para o socket.
- **Interface** (`interface.sock`): o shell (`shell/ServidorSistema.qml`) se conecta aqui. Recebe os pedidos de confirmação (`shell/ConfirmacaoAcao.qml`), os comandos de tela (abrir pastas, mudar a esfera, trocar cores, áreas) e cada registro novo do histórico.
- **Lista de ferramentas** (`terminus-mcp ferramentas`): imprime em JSON o nome, grupo, descrição e nível de cada uma. É o que a página Configurações → Usuários e segurança usa.

## Níveis de permissão

| Nível | O que acontece |
|---|---|
| `livre` | Roda direto. |
| `confirmacao` | O shell mostra o pedido acima de tudo; o usuário permite ou nega. Sem resposta em 60 s, ou sem shell aberto, é negado. A confirmação por voz entra com o assistente (fase 4). |
| `senha` | O shell pede a senha do usuário e o **servidor** confere, com o `unix_chkpwd` do PAM (o mesmo do login). A senha nunca vai para o histórico. |

O usuário troca o nível de qualquer ferramenta em Configurações → Usuários e segurança. A escolha fica em `~/.config/terminus/pessoal/permissoes.json` (camada pessoal, nunca sobrescrita):

```json
{ "ferramentas": { "pasta_criar": "senha", "janela_fechar": "livre" } }
```

Ferramentas **críticas** (desligar e reiniciar) nunca ficam abaixo de `senha`, mesmo que o arquivo diga outra coisa.

## Histórico

Cada chamada vira uma linha em `~/.local/state/terminus/historico.jsonl`: data, cliente (o nome que o cliente MCP informou), ferramenta, argumentos (sem nada que se chame "senha" e com textos longos cortados), nível, resultado (`feito`, `negado` ou `erro`) e o motivo. Guarda as últimas 5000. A página de segurança mostra as 100 mais recentes e a ferramenta `historico_listar` deixa o próprio assistente consultar.

## Ferramentas

Os arquivos ficam restritos à pasta pessoal: caminhos fora dela são recusados.

| Grupo | Ferramenta | Nível padrão | O que faz |
|---|---|---|---|
| sistema | `sistema_info` | livre | Nome do computador, processador, memória, disco e tempo ligado |
| sistema | `volume_ler` | livre | Volume da saída de som e se está mudo |
| sistema | `volume_definir` | livre | Muda o volume (0 a 100) ou deixa mudo |
| apps | `apps_listar` | livre | Apps instalados (id, nome, descrição), com filtro por nome |
| apps | `app_abrir` | livre | Abre um app pelo id |
| janelas | `janelas_listar` | livre | Janelas abertas (endereço, app, título) |
| janelas | `janela_focar` | livre | Traz uma janela para a frente |
| janelas | `janela_fechar` | confirmação | Fecha uma janela (o app pode pedir para salvar) |
| arquivos | `arquivos_listar` | livre | Conteúdo de uma pasta |
| arquivos | `arquivo_ler` | livre | Lê um arquivo de texto (até 64 KB) |
| arquivos | `pasta_criar` | livre | Cria uma pasta |
| arquivos | `arquivo_mover` | confirmação | Move ou renomeia, sem sobrescrever |
| arquivos | `arquivo_lixeira` | confirmação | Manda para a Lixeira (dá para restaurar) |
| interface | `tela_abrir` | livre | Abre busca, pastas, configurações ou notificações |
| interface | `esfera_estado` | livre | Muda o estado da esfera |
| interface | `cores_definir` | livre | Troca o preset de cores |
| interface | `avisar` | livre | Mostra uma notificação |
| areas | `areas_listar` | livre | Áreas de atalho e seus atalhos |
| areas | `area_criar` | livre | Cria uma área, com apps se quiser |
| areas | `area_minimizar` | livre | Minimiza ou abre uma área |
| energia | `energia_suspender` | confirmação | Suspende o computador |
| energia | `energia_reiniciar` | senha (crítica) | Reinicia |
| energia | `energia_desligar` | senha (crítica) | Desliga |
| historico | `historico_listar` | livre | Últimas ações pedidas ao sistema |

Ainda não entram: rede e Bluetooth, telas e brilho, instalar e remover apps, atualizações, jogos e VM. Cada um chega junto com a sua página nas Configurações.

### Ferramenta nova

Em `terminus_mcp/ferramentas.py`, uma função assíncrona com o decorador:

```python
@ferramenta("nome_da_ferramenta", "grupo", "Descrição curta, que o modelo lê.",
            nivel=CONFIRMACAO, parametros={"caminho": texto("o que é")}, obrigatorios=["caminho"],
            resumo=lambda a: f"Frase que aparece no pedido de confirmação: {a['caminho']}")
async def nome_da_ferramenta(contexto, caminho):
    ...
    return "texto ou dicionário com o resultado"
```

Erros esperados sobem como `ErroFerramenta("mensagem para o usuário")`. Comandos externos passam por `executar(...)`, que tem tempo limite.

## Conectar um cliente

O Claude Code (conta do usuário, nunca API paga):

```bash
claude mcp add terminus -- terminus-mcp stdio
```

Qualquer outro cliente MCP que rode comandos por stdio usa o mesmo `terminus-mcp stdio`.

## Testes

```bash
cd mcp && python3 -m unittest discover -s testes -v
```

Sobem o servidor num diretório temporário com uma interface falsa e conversam com ele pela ponte stdio. O teste da senha certa só roda com `SENHA_TESTE` definida (no GitHub Actions, o usuário de teste ganha uma senha para isso).

## Limites conhecidos

- A confirmação simples protege contra o assistente agir sozinho, não contra outro programa do mesmo usuário: um programa que se conecte ao `interface.sock` no lugar do shell pode aprovar pedidos de nível `confirmacao`. Pedidos de nível `senha` não, porque quem confere a senha é o servidor.
- As IAs de programação também têm o próprio terminal; as permissões daqui valem para o que passa pelo MCP. O que elas fazem pelo terminal segue as permissões delas (no Claude Code, as de `/permissions`).
