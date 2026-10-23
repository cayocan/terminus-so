"""Avalia um modelo servido pelo llama-server (API compatível com OpenAI) para o assistente do Terminus:
português, velocidade e escolha das ferramentas reais do servidor MCP.

    llama-server -m modelo.gguf -ngl 99 -c 8192 --jinja --port 8090
    python3 assistente/avaliacao/avaliar_modelo.py <rotulo> [--pensar]

Só lê a lista de ferramentas do MCP, não executa nenhuma. O resultado vai para assistente/avaliacao/<rotulo>.json.
"""
import json, os, sys, time, urllib.request
from pathlib import Path

AQUI = Path(__file__).resolve().parent
os.environ.setdefault("XDG_RUNTIME_DIR", "/tmp")
sys.path.insert(0, str(AQUI.parents[1] / "mcp"))
from terminus_mcp import ferramentas as F

URL = os.environ.get("LLAMA_URL", "http://127.0.0.1:8090") + "/v1/chat/completions"
ROTULO = sys.argv[1]
PENSAR = "--pensar" in sys.argv

SISTEMA = ("Você é Jarvis, o assistente de voz do Terminus SO, um sistema Linux. Responda sempre em português do "
           "Brasil, curto e natural, como numa conversa falada (sem listas nem markdown). Use as ferramentas para "
           "agir no sistema; não invente resultados.")

FERRAMENTAS = [{"type": "function", "function": {"name": f.nome, "description": f.descricao,
                                                 "parameters": f.esquema()}} for f in F.REGISTRO.values()]


def pedir(mensagens, ferramentas=True):
    corpo = {"messages": mensagens, "temperature": 0.6, "max_tokens": 700,
             "chat_template_kwargs": {"enable_thinking": PENSAR}}
    if ferramentas:
        corpo["tools"] = FERRAMENTAS
    req = urllib.request.Request(URL, json.dumps(corpo).encode(), {"Content-Type": "application/json"})
    inicio = time.time()
    with urllib.request.urlopen(req, timeout=300) as r:
        resposta = json.load(r)
    return resposta, time.time() - inicio


# Pedido falado → ferramenta(s) aceitáveis e checagem dos argumentos (None = não deve chamar nenhuma).
CASOS_FERRAMENTA = [
    ("abre o firefox pra mim", {"app_abrir", "apps_listar"}, lambda a: "firefox" in json.dumps(a).lower() or a == {}),
    ("quanto de memória livre eu tenho?", {"sistema_info"}, None),
    ("minimiza a área de trabalho", {"area_minimizar", "areas_listar"}, lambda a: "trabalho" in json.dumps(a).lower() or a == {}),
    ("cria uma área chamada Estudos", {"area_criar"}, lambda a: "estudos" in a.get("nome", "").lower()),
    ("baixa o volume pra trinta por cento", {"volume_definir"}, lambda a: a.get("volume") in (30, "30")),
    ("muda as cores pro modo stealth", {"cores_definir"}, lambda a: "stealth" in json.dumps(a).lower()),
    ("desliga o computador", {"energia_desligar"}, None),
    ("manda o arquivo ~/Downloads/velho.zip pra lixeira", {"arquivo_lixeira"}, lambda a: "velho.zip" in json.dumps(a)),
    ("o que tem na minha pasta Documentos?", {"arquivos_listar"}, lambda a: "documentos" in json.dumps(a).lower()),
    ("me conta uma curiosidade sobre o espaço", None, None),
]

CASOS_TEXTO = [
    "Resuma em duas frases faladas estas notificações não lidas: 3 e-mails do banco sobre a fatura, "
    "1 mensagem da Ana perguntando do almoço de sábado, atualização do Steam concluída.",
    "Explique em poucas frases, para alguém leigo, o que é uma partição de disco.",
    "Bom dia! Como você pode me ajudar hoje?",
]


def principal():
    saida = {"rotulo": ROTULO, "pensar": PENSAR, "ferramentas": [], "texto": []}
    acertos = 0
    for pedido, esperadas, checar in CASOS_FERRAMENTA:
        r, t = pedir([{"role": "system", "content": SISTEMA}, {"role": "user", "content": pedido}])
        m = r["choices"][0]["message"]
        chamadas = [(c["function"]["name"], json.loads(c["function"]["arguments"] or "{}"))
                    for c in (m.get("tool_calls") or [])]
        if esperadas is None:
            ok = not chamadas
        else:
            ok = bool(chamadas) and chamadas[0][0] in esperadas and (checar is None or checar(chamadas[0][1]))
        acertos += ok
        saida["ferramentas"].append({"pedido": pedido, "ok": ok, "chamadas": chamadas, "segundos": round(t, 2),
                                     "texto": (m.get("content") or "")[:200]})
        print(("OK  " if ok else "ERR ") + f"{t:5.1f}s {pedido!r} -> {chamadas or (m.get('content') or '')[:80]!r}")
    print(f"ferramentas: {acertos}/{len(CASOS_FERRAMENTA)}")

    for pedido in CASOS_TEXTO:
        r, t = pedir([{"role": "system", "content": SISTEMA}, {"role": "user", "content": pedido}], ferramentas=False)
        tm = r.get("timings", {})
        texto = r["choices"][0]["message"].get("content") or ""
        saida["texto"].append({"pedido": pedido, "resposta": texto, "segundos": round(t, 2),
                               "tok_s": round(tm.get("predicted_per_second", 0), 1),
                               "prompt_tok_s": round(tm.get("prompt_per_second", 0), 1)})
        print(f"\n[{t:.1f}s, {tm.get('predicted_per_second', 0):.1f} tok/s] {pedido[:50]}...\n{texto}")
    saida["acertos"] = acertos
    with open(AQUI / f"{ROTULO}.json", "w", encoding="utf-8") as f:
        json.dump(saida, f, ensure_ascii=False, indent=1)


principal()
