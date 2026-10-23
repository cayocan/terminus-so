"""Teste de ponta a ponta do servidor MCP, sem a interface de verdade: sobe o servidor num diretório
temporário, conecta uma interface falsa (que aprova, nega ou manda senha conforme o caso) e conversa com o
servidor pela ponte stdio, como um cliente MCP faria.

    python3 -m unittest discover -s mcp/testes
"""

import json
import os
import subprocess
import sys
import tempfile
import threading
import time
import unittest
import socket
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[1]


class InterfaceFalsa(threading.Thread):
    def __init__(self, caminho, decisao):
        super().__init__(daemon=True)
        self.caminho, self.decisao, self.recebidas = caminho, decisao, []

    def run(self):
        conexao = socket.socket(socket.AF_UNIX)
        conexao.connect(self.caminho)
        arquivo = conexao.makefile("rw", encoding="utf-8")
        for linha in arquivo:
            mensagem = json.loads(linha)
            self.recebidas.append(mensagem)
            if "id" not in mensagem or mensagem.get("tipo") == "cancelar":
                continue
            resposta = {"id": mensagem["id"], "tipo": "resposta", **self.decisao(mensagem)}
            arquivo.write(json.dumps(resposta) + "\n")
            arquivo.flush()


class TesteServidor(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        base = Path(self.temp.name)
        (base / "casa/Documentos").mkdir(parents=True)
        (base / "casa/Documentos/nota.txt").write_text("olá")
        self.ambiente = dict(os.environ, HOME=str(base / "casa"), XDG_RUNTIME_DIR=str(base / "run"),
                             XDG_STATE_HOME=str(base / "estado"), XDG_CONFIG_HOME=str(base / "config"),
                             PYTHONPATH=str(RAIZ))
        self.casa = base / "casa"
        self.servidor = subprocess.Popen([sys.executable, "-m", "terminus_mcp", "servidor"],
                                         env=self.ambiente, stderr=subprocess.DEVNULL)
        self.socket_interface = base / "run/terminus/interface.sock"
        for _ in range(50):
            if (base / "run/terminus/mcp.sock").exists():
                break
            time.sleep(0.1)
        self.historico = base / "estado/terminus/historico.jsonl"

    def tearDown(self):
        self.servidor.terminate()
        self.servidor.wait()
        self.temp.cleanup()

    def conversar(self, pedidos):
        """Manda as mensagens pela ponte stdio e devolve as respostas (só as que têm id)."""
        entrada = "".join(json.dumps(p) + "\n" for p in pedidos)
        ponte = subprocess.run([sys.executable, "-m", "terminus_mcp", "stdio"], input=entrada,
                               capture_output=True, text=True, env=self.ambiente, timeout=30)
        return [json.loads(l) for l in ponte.stdout.splitlines()]

    def chamar(self, nome, argumentos=None):
        respostas = self.conversar([
            {"jsonrpc": "2.0", "id": 1, "method": "initialize",
             "params": {"protocolVersion": "2025-06-18", "clientInfo": {"name": "teste"}, "capabilities": {}}},
            {"jsonrpc": "2.0", "method": "notifications/initialized"},
            {"jsonrpc": "2.0", "id": 2, "method": "tools/call", "params": {"name": nome, "arguments": argumentos or {}}},
        ])
        return respostas[-1]["result"]

    def interface(self, decisao):
        falsa = InterfaceFalsa(str(self.socket_interface), decisao)
        falsa.start()
        time.sleep(0.3)
        return falsa

    def test_inicializa_e_lista(self):
        respostas = self.conversar([
            {"jsonrpc": "2.0", "id": 1, "method": "initialize",
             "params": {"protocolVersion": "2025-06-18", "clientInfo": {"name": "teste"}, "capabilities": {}}},
            {"jsonrpc": "2.0", "id": 2, "method": "tools/list"},
        ])
        self.assertEqual(respostas[0]["result"]["serverInfo"]["name"], "terminus")
        nomes = {f["name"] for f in respostas[1]["result"]["tools"]}
        self.assertTrue({"arquivos_listar", "janela_fechar", "energia_desligar", "historico_listar"} <= nomes)

    def test_livre_roda_e_vai_para_o_historico(self):
        resultado = self.chamar("arquivos_listar", {"pasta": "~/Documentos"})
        self.assertFalse(resultado["isError"])
        self.assertEqual(resultado["structuredContent"]["itens"][0]["nome"], "nota.txt")
        registro = json.loads(self.historico.read_text().splitlines()[-1])
        self.assertEqual((registro["ferramenta"], registro["resultado"], registro["cliente"]),
                         ("arquivos_listar", "feito", "teste"))

    def test_fora_da_pasta_pessoal_recusa(self):
        resultado = self.chamar("arquivo_ler", {"caminho": "/etc/passwd"})
        self.assertTrue(resultado["isError"])
        self.assertIn("fora da pasta pessoal", resultado["content"][0]["text"])

    def test_confirmacao_sem_interface_nega(self):
        resultado = self.chamar("arquivo_mover", {"origem": "~/Documentos/nota.txt", "destino": "~/nota.txt"})
        self.assertTrue(resultado["isError"])
        self.assertTrue((self.casa / "Documentos/nota.txt").exists())

    def test_confirmacao_aprovada_executa(self):
        falsa = self.interface(lambda m: {"ok": True})
        resultado = self.chamar("arquivo_mover", {"origem": "~/Documentos/nota.txt", "destino": "~/nota.txt"})
        self.assertFalse(resultado["isError"], resultado)
        self.assertTrue((self.casa / "nota.txt").exists())
        pedido = next(m for m in falsa.recebidas if m.get("tipo") == "confirmar")
        self.assertEqual(pedido["nivel"], "confirmacao")
        self.assertIn("nota.txt", pedido["resumo"])

    def test_confirmacao_negada_nao_executa(self):
        self.interface(lambda m: {"ok": False})
        resultado = self.chamar("arquivo_mover", {"origem": "~/Documentos/nota.txt", "destino": "~/nota.txt"})
        self.assertTrue(resultado["isError"])
        self.assertTrue((self.casa / "Documentos/nota.txt").exists())
        registro = json.loads(self.historico.read_text().splitlines()[-1])
        self.assertEqual(registro["resultado"], "negado")

    def test_senha_errada_nao_executa(self):
        # Sem a senha certa (o unix_chkpwd recusa), energia_desligar nunca chega ao systemctl.
        self.interface(lambda m: {"ok": True, "senha": "errada"})
        resultado = self.chamar("energia_desligar")
        self.assertTrue(resultado["isError"])
        self.assertIn("senha incorreta", resultado["content"][0]["text"])
        self.assertNotIn("errada", self.historico.read_text())

    @unittest.skipUnless(os.environ.get("SENHA_TESTE"), "defina SENHA_TESTE com a senha do usuário que roda o teste")
    def test_senha_certa_executa(self):
        # No CI o usuário de teste ganha senha; assim a conferência de verdade (unix_chkpwd) também é testada.
        config = Path(self.ambiente["XDG_CONFIG_HOME"]) / "terminus/pessoal"
        config.mkdir(parents=True)
        (config / "permissoes.json").write_text(json.dumps({"ferramentas": {"pasta_criar": "senha"}}))
        self.interface(lambda m: {"ok": True, "senha": os.environ["SENHA_TESTE"]})
        resultado = self.chamar("pasta_criar", {"caminho": "~/Nova"})
        self.assertFalse(resultado["isError"], resultado["content"][0]["text"])
        self.assertTrue((self.casa / "Nova").is_dir())

    def test_critica_nao_desce_de_senha(self):
        config = Path(self.ambiente["XDG_CONFIG_HOME"]) / "terminus/pessoal"
        config.mkdir(parents=True)
        (config / "permissoes.json").write_text(json.dumps(
            {"ferramentas": {"energia_desligar": "livre", "arquivo_mover": "livre"}}))
        lista = subprocess.run([sys.executable, "-m", "terminus_mcp", "ferramentas"], env=self.ambiente,
                               capture_output=True, text=True).stdout
        niveis = {f["nome"]: f["nivel"] for f in json.loads(lista)}
        self.assertEqual(niveis["energia_desligar"], "senha")
        self.assertEqual(niveis["arquivo_mover"], "livre")

    def test_comando_de_tela_passa_pela_interface(self):
        falsa = self.interface(lambda m: {"ok": True, "dados": "aberta"})
        resultado = self.chamar("tela_abrir", {"tela": "pastas", "detalhe": "~/Documentos"})
        self.assertFalse(resultado["isError"])
        comando = next(m for m in falsa.recebidas if m.get("tipo") == "comando")
        self.assertEqual((comando["acao"], comando["args"]["tela"]), ("abrir", "pastas"))


if __name__ == "__main__":
    unittest.main()
