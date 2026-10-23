# Assistente local

Modelo local (llama.cpp com Vulkan) que age no sistema só pelas ferramentas do servidor MCP (`mcp/`), com os níveis de permissão e o histórico de lá. Fase 4 do roadmap. Ainda faltam a voz (whisper.cpp para ouvir, Piper para falar) e a palavra de ativação (openWakeWord); até lá, a conversa é digitada.

Python 3 puro, sem dependências, como o MCP.

## Como funciona

```
shell (Quickshell) ──assistente.sock──► terminus-assistente ──HTTP──► llama-server (127.0.0.1:8091)
  PerguntaAssistente.qml                       │
  (clique na esfera ou Super + A)              └──mcp.sock──► terminus-mcp ──► ferramentas
                                                                   │
                                     ConfirmacaoAcao.qml ◄─────────┘ (confirmação ou senha)
```

- **Serviço** (`terminus-assistente servidor`): serviço de usuário do systemd (`terminus-assistente.service`), iniciado pelo Hyprland junto com o `terminus-mcp`. Escolhe o modelo, sobe um llama-server só para ele (escutando apenas no próprio computador), aquece o cache e atende o shell no socket `$XDG_RUNTIME_DIR/terminus/assistente.sock`.
- **Laço** (`laco.py`): a pergunta vai para o modelo com as ferramentas do MCP; cada ferramenta pedida passa pelo servidor do sistema, que pede confirmação ou senha quando o nível manda; o resultado volta para o modelo até ele responder em texto. No máximo 6 passos por pergunta. A conversa é lembrada por 5 minutos (últimas 12 mensagens).
- **No histórico do MCP**, o cliente aparece com o nome que o usuário deu ao assistente (Configurações → Esfera e assistente).
- **Shell**: `Assistente.qml` é a ligação com o serviço; `PerguntaAssistente.qml` é a caixa de conversa (mesmo visual da busca), com o download do modelo no primeiro uso; a esfera mostra pensando e falando, e a resposta aparece embaixo dela na tela principal.

Comandos:

```bash
terminus-assistente perguntar "quanto de memória livre eu tenho?"   # a resposta também aparece na tela
terminus-assistente modelos                                       # modelos e qual está em uso
terminus-assistente escolher qwen3-1.7b                           # troca o modelo (reinicie o serviço)
terminus-assistente baixar                                        # baixa sem esperar o primeiro uso
```

## llama.cpp na ISO

O Debian 13 não empacota o llama.cpp. O hook `iso/config/hooks/normal/0600-llama.hook.chroot` instala o binário oficial Vulkan para Linux (b11838, sha256 conferido) em `/opt/llama.cpp`, com `llama-server` e `llama-bench` no PATH. São 82 MB; compilar os shaders Vulkan na build levaria muito mais tempo.

## Modelos e download no primeiro uso

Os modelos não vão na ISO. Na primeira conversa, a caixa oferece o download (com progresso e Cancelar); o arquivo vai para `~/.local/share/terminus/modelos`, continua de onde parou se cair e só é usado depois de conferir o sha256. Antes de começar, confere se há espaço; no pendrive (modo live) os arquivos ficam na RAM, e o aviso diz isso.

| Modelo | Quando | Tamanho | Ferramentas (10 pedidos) |
|---|---|---|---|
| Qwen3 8B Q4_K_M | padrão, placa de vídeo com 6 GB ou mais | 5,0 GB | 10/10 |
| Qwen3 1.7B Q8_0 | sem placa Vulkan ou com menos memória de vídeo | 1,8 GB | 9/10 |

A escolha é automática (pela memória de vídeo livre que o llama.cpp enxerga) e pode ser trocada com `terminus-assistente escolher`. Os dois vêm dos repositórios oficiais `Qwen/Qwen3-*-GGUF`, com tamanho e sha256 fixos em `modelos.py`.

### Qwen3 8B no PC de referência

Ryzen 7 1800X, Radeon RX 5500 XT 8 GB, llama.cpp b11838 Vulkan, 23/10/2026.

- **Velocidade**: 24 tokens/s gerando, 109 tokens/s lendo prompts longos (llama-bench).
- **Ferramentas**: 10 de 10 pedidos falados com a ferramenta e os argumentos certos, nas duas rodadas ([avaliacao/qwen3-8b-q4_k_m.json](avaliacao/qwen3-8b-q4_k_m.json)).
- **Laço completo** (pergunta → ferramenta → resposta, duas idas ao modelo): de 3 a 6 s por pergunta, com o cache aquecido. Entende continuações ("e o que está escrito no arquivo de compras?").
- **Português**: natural e curto. Às vezes termina oferecendo algo ("Deseja instalar?").

### Qwen3 1.7B

9 de 10 nos pedidos isolados, com ou sem o modo de raciocínio ([avaliacao/qwen3-1.7b-q8_0.json](avaliacao/qwen3-1.7b-q8_0.json)), então fica sem. Na conversa de verdade erra mais: escolhe a ferramenta errada em continuações, monta caminhos errados e às vezes escreve o nome da ferramenta em vez de chamá-la (o laço trata isso como a chamada, quando a ferramenta não tem argumentos obrigatórios). O português é fraco para fatos. Serve para PCs sem placa de vídeo; na VM de teste, sem Vulkan, rodou no processador.

## Ajustes que vieram dos testes

- **Sem flash attention** (`-fa off`). O llama-server liga sozinho, e na RX 5500 XT a leitura da pergunta depois das ~2200 tokens das ferramentas cai de 85 para 24 tokens/s (`llama-bench -d 2300 -fa 0,1`). Com isso, cada pergunta ficou duas a três vezes mais rápida.
- **Instruções fixas.** As ferramentas vêm logo depois das instruções no prompt; se elas mudarem (com a hora, por exemplo), o llama-server relê tudo a cada pergunta. A data e a hora vão junto da fala do usuário.
- **Aquecimento ao subir.** A frio, ler as instruções e as ferramentas leva quase um minuto na GPU (bem mais no processador); o serviço faz isso antes de dizer que está pronto.
- **Sem o modo de raciocínio do Qwen3**: para conversa falada cada segundo conta, e não melhorou as ferramentas.

## Avaliar outro modelo

```bash
llama-server -m outro-modelo.gguf -ngl 99 -c 8192 -fa off --jinja --port 8090
python3 assistente/avaliacao/avaliar_modelo.py rotulo-do-modelo
```

O roteiro manda pedidos falados com a lista real de ferramentas do MCP (não executa nenhuma), confere qual ferramenta e quais argumentos o modelo escolheu, e mede velocidade e português em três respostas faladas. Com `--pensar`, liga o modo de raciocínio.

## Testes

```bash
cd assistente && python3 -m unittest discover -s testes -v
```

Um llama-server falso (que responde por roteiro) e o servidor MCP de verdade, num diretório temporário: ferramenta executada e resultado de volta ao modelo, resposta sem ferramenta, ação negada contada ao usuário, modelo andando em círculo, nome de ferramenta escrito como texto, começo do prompt fixo para o cache e o pedido de download quando não há modelo. Rodam no GitHub Actions antes da ISO.
