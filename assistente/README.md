# Assistente local

Palavra de ativação (openWakeWord), voz para texto (whisper.cpp), modelo local (llama.cpp com Vulkan) e voz (Piper, com XTTS v2 / F5-TTS opcional). Fase 4 do roadmap. Tudo roda no computador; o modelo age no sistema só pelas ferramentas do servidor MCP (`mcp/`), com os níveis de permissão e o histórico de lá.

## Modelo padrão: Qwen3 8B (Q4_K_M)

Escolhido em 23/10/2026 no PC de referência (Ryzen 7 1800X, Radeon RX 5500 XT 8 GB), com o llama.cpp b11838 Vulkan.

| Medida | Resultado |
|---|---|
| Arquivo | `Qwen3-8B-Q4_K_M.gguf`, do repositório oficial `Qwen/Qwen3-8B-GGUF`, 4,7 GB |
| Velocidade (llama-bench, tudo na GPU) | 24 tokens/s gerando, 109 tokens/s lendo o prompt |
| Ferramentas do MCP | 10 de 10 pedidos falados com a ferramenta e os argumentos certos, nas duas rodadas |
| Tempo por pedido | cerca de 2 s até a chamada da ferramenta; respostas faladas curtas em 1,5 a 2,5 s |
| Português | natural e correto nas respostas curtas; resumo de notificações e explicação para leigo bons |

O resultado completo está em [avaliacao/qwen3-8b-q4_k_m.json](avaliacao/qwen3-8b-q4_k_m.json).

Configuração usada:

- `llama-server -m Qwen3-8B-Q4_K_M.gguf -ngl 99 -c 8192 --jinja`: `--jinja` liga o modelo de chat do próprio arquivo, que é o que faz as chamadas de ferramenta funcionarem.
- Sem o modo de raciocínio do Qwen3 (`"chat_template_kwargs": {"enable_thinking": false}`): para voz, cada segundo conta, e mesmo assim acertou todas as ferramentas.
- Instrução de sistema pedindo português do Brasil, frases curtas e sem markdown, porque a resposta vai ser falada.

Cuidados que ficaram do teste:

- **Primeiro pedido lento.** As instruções e a descrição das 24 ferramentas somam uns 2100 tokens; a frio, o primeiro pedido levou 53 s. Depois disso o llama-server guarda esse começo em cache e cada pedido novo lê só a frase do usuário. O assistente vai fazer um pedido de aquecimento ao subir, antes de o usuário falar.
- **Nomes aproximados.** O modelo diz "área de trabalho" para a área "Trabalho". O shell já compara sem acento e sem o prefixo "área de/do/da/dos/das".
- **Dois passos para abrir app.** Para "abre o Firefox" ele primeiro chama `apps_listar` para achar o id; o laço do assistente precisa devolver o resultado e deixar o modelo chamar `app_abrir` em seguida.

O modelo não vai dentro da ISO (são 4,7 GB). Ele é baixado no onboarding ou na primeira vez que o assistente liga.

## Avaliar outro modelo

```bash
llama-server -m outro-modelo.gguf -ngl 99 -c 8192 --jinja --port 8090
python3 assistente/avaliacao/avaliar_modelo.py rotulo-do-modelo
```

O roteiro manda pedidos falados com a lista real de ferramentas do MCP (não executa nenhuma), confere qual ferramenta e quais argumentos o modelo escolheu, e mede velocidade e português em três respostas faladas. Com `--pensar` liga o modo de raciocínio, para modelos que têm.
