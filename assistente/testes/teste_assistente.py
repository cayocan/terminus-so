"""Teste de ponta a ponta do assistente sem modelo de verdade: um llama-server falso (que responde conforme um
roteiro) e o servidor MCP de verdade, num diretório temporário. Confere o laço pergunta → ferramenta → resposta.

    python3 -m unittest discover -s assistente/testes
"""

import json
import os
import subprocess
import sys
import tempfile
import threading
import time
import unittest
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[2]


class LlamaFalso(BaseHTTPRequestHandler):
    """Responde como o llama-server: pedidos com "pasta" chamam pasta_criar, com "lixeira" chamam arquivo_lixeira,
    com "círculo" chamam sistema_info para sempre; depois de uma ferramenta, devolve o resultado como texto."""
    pedidos = []

    def log_message(self, *args):
        pass

    def do_GET(self):
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b'{"status": "ok"}')

    def do_POST(self):
        corpo = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
        LlamaFalso.pedidos.append(corpo)
        ultima = corpo["messages"][-1]
        texto = ultima.get("content") or ""
        mensagem = {"role": "assistant", "content": "Oi! Tudo certo por aqui."}
        em_circulo = any(m["role"] == "user" and "círculo" in m["content"] for m in corpo["messages"])
        if ultima["role"] == "tool":
            mensagem = self.chamada("sistema_info", {}) if em_circulo else \
                {"role": "assistant", "content": "Resultado: " + texto}
        elif "pasta" in texto:
            mensagem = self.chamada("pasta_criar", {"caminho": "~/Nova"})
        elif "lixeira" in texto:
            mensagem = self.chamada("arquivo_lixeira", {"caminho": "~/Documentos/nota.txt"})
        elif "círculo" in texto:
            mensagem = self.chamada("sistema_info", {})
        elif "nome solto" in texto:
            mensagem = {"role": "assistant", "content": "sistema_info"}
        dados = json.dumps({"choices": [{"message": mensagem}]}).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(dados)))
        self.end_headers()
        self.wfile.write(dados)

    @staticmethod
    def chamada(nome, argumentos):
        return {"role": "assistant", "content": "", "tool_calls": [
            {"id": f"c{len(LlamaFalso.pedidos)}", "type": "function",
             "function": {"name": nome, "arguments": json.dumps(argumentos)}}]}


class TesteAssistente(unittest.TestCase):
    def setUp(self):
        LlamaFalso.pedidos = []
        self.http = ThreadingHTTPServer(("127.0.0.1", 0), LlamaFalso)
        threading.Thread(target=self.http.serve_forever, daemon=True).start()
        self.temp = tempfile.TemporaryDirectory()
        base = Path(self.temp.name)
        self.casa = base / "casa"
        (self.casa / "Documentos").mkdir(parents=True)
        (self.casa / "Documentos/nota.txt").write_text("olá")
        pessoal = base / "config/terminus/pessoal"
        pessoal.mkdir(parents=True)
        (pessoal / "configuracoes.json").write_text(json.dumps({"nomeAssistente": "Jarvis"}))
        self.ambiente = dict(os.environ, HOME=str(self.casa), XDG_RUNTIME_DIR=str(base / "run"),
                             XDG_STATE_HOME=str(base / "estado"), XDG_CONFIG_HOME=str(base / "config"),
                             XDG_DATA_HOME=str(base / "dados"), TERMINUS_LLAMA_SERVER="/nao/existe",
                             TERMINUS_LLAMA_URL=f"http://127.0.0.1:{self.http.server_port}")
        self.historico = base / "estado/terminus/historico.jsonl"
        self.processos = []
        self.subir("mcp", "terminus_mcp", base / "run/terminus/mcp.sock")

    def subir(self, pasta, modulo, socket, ambiente=None):
        processo = subprocess.Popen([sys.executable, "-m", modulo, "servidor"],
                                    env=dict(ambiente or self.ambiente, PYTHONPATH=str(RAIZ / pasta)),
                                    stderr=subprocess.DEVNULL)
        self.processos.append(processo)
        for _ in range(100):
            if socket.exists():
                return
            time.sleep(0.1)
        self.fail(f"{modulo} não subiu")

    def tearDown(self):
        for processo in self.processos:
            processo.terminate()
            processo.wait()
        self.http.shutdown()
        self.temp.cleanup()

    def subir_assistente(self, ambiente=None):
        self.subir("assistente", "terminus_assistente", Path(self.temp.name) / "run/terminus/assistente.sock",
                   ambiente)
        # Espera o aquecimento (o primeiro pedido ao modelo) terminar.
        for _ in range(100):
            if LlamaFalso.pedidos or ambiente:
                break
            time.sleep(0.1)
        time.sleep(0.3)

    def perguntar(self, texto, ambiente=None):
        saida = subprocess.run([sys.executable, "-m", "terminus_assistente", "perguntar", texto],
                               env=dict(ambiente or self.ambiente, PYTHONPATH=str(RAIZ / "assistente")),
                               capture_output=True, text=True, timeout=60)
        return saida.stdout.strip()

    def test_ferramenta_executa_e_resultado_volta_ao_modelo(self):
        self.subir_assistente()
        resposta = self.perguntar("cria uma pasta Nova")
        self.assertTrue((self.casa / "Nova").is_dir())
        self.assertIn("pronta", resposta)
        registro = json.loads(self.historico.read_text().splitlines()[-1])
        self.assertEqual((registro["cliente"], registro["ferramenta"]), ("Jarvis", "pasta_criar"))

    def test_resposta_sem_ferramenta(self):
        self.subir_assistente()
        self.assertEqual(self.perguntar("bom dia"), "Oi! Tudo certo por aqui.")
        self.assertFalse(self.historico.exists())

    def test_acao_negada_volta_como_texto(self):
        # Sem o shell aberto, a confirmação é negada: o modelo recebe o motivo e conta ao usuário.
        self.subir_assistente()
        resposta = self.perguntar("manda a nota pra lixeira")
        self.assertIn("interface", resposta)
        self.assertTrue((self.casa / "Documentos/nota.txt").exists())

    def test_modelo_em_circulo_para(self):
        self.subir_assistente()
        resposta = self.perguntar("anda em círculo")
        self.assertIn("Não consegui terminar", resposta)

    def test_nome_de_ferramenta_escrito_vale_como_chamada(self):
        # Modelo pequeno escreve "sistema_info" em vez de chamar: a ferramenta roda e o resultado volta.
        self.subir_assistente()
        resposta = self.perguntar("nome solto")
        self.assertIn("Resultado:", resposta)
        registro = json.loads(self.historico.read_text().splitlines()[-1])
        self.assertEqual(registro["ferramenta"], "sistema_info")

    def test_inicio_do_prompt_fixo_para_o_cache(self):
        # Instruções e ferramentas iguais em todo pedido: é o que deixa o llama-server reaproveitar o cache.
        self.subir_assistente()
        self.perguntar("bom dia")
        self.perguntar("cria uma pasta Nova")
        sistemas = {p["messages"][0]["content"] for p in LlamaFalso.pedidos}
        ferramentas = {json.dumps(p.get("tools"), sort_keys=True) for p in LlamaFalso.pedidos}
        self.assertEqual(len(sistemas), 1)
        self.assertEqual(len(ferramentas), 1)
        self.assertIn("Jarvis", sistemas.pop())

    def test_sem_modelo_pede_download(self):
        ambiente = {k: v for k, v in self.ambiente.items() if k != "TERMINUS_LLAMA_URL"}
        self.subir_assistente(ambiente)
        resposta = self.perguntar("bom dia", ambiente)
        self.assertIn("preciso baixar o modelo Qwen3 1.7B", resposta)
        self.assertEqual(LlamaFalso.pedidos, [])


if __name__ == "__main__":
    unittest.main()
