"""Ponte com a interface (Quickshell): o shell se conecta neste socket e recebe pedidos de confirmação e
comandos de tela; responde pelo mesmo canal. Mensagens em JSON, uma por linha:

    servidor → shell  {"id": 3, "tipo": "confirmar", "nivel": "senha", "ferramenta": "...", "resumo": "..."}
                      {"id": 4, "tipo": "comando", "acao": "abrir", "args": {...}}
                      {"tipo": "historico", "registro": {...}}
    shell → servidor  {"id": 3, "tipo": "resposta", "ok": true, "senha": "..."}
                      {"id": 4, "tipo": "resposta", "ok": true, "dados": {...}}
"""

import asyncio
import itertools
import json
import os

from . import caminhos

TEMPO_CONFIRMACAO = 60


class Interface:
    def __init__(self):
        self._escritor = None
        self._pendentes = {}
        self._ids = itertools.count(1)

    @property
    def conectada(self):
        return self._escritor is not None and not self._escritor.is_closing()

    async def iniciar(self):
        caminhos.RUNTIME.mkdir(parents=True, exist_ok=True, mode=0o700)
        if caminhos.SOCKET_INTERFACE.exists():
            caminhos.SOCKET_INTERFACE.unlink()
        servidor = await asyncio.start_unix_server(self._atender, path=str(caminhos.SOCKET_INTERFACE))
        os.chmod(caminhos.SOCKET_INTERFACE, 0o600)
        return servidor

    async def _atender(self, leitor, escritor):
        # Só uma interface por vez: a mais recente assume.
        if self.conectada:
            self._escritor.close()
        self._escritor = escritor
        try:
            while linha := await leitor.readline():
                try:
                    mensagem = json.loads(linha)
                except json.JSONDecodeError:
                    continue
                futuro = self._pendentes.pop(mensagem.get("id"), None)
                if futuro and not futuro.done():
                    futuro.set_result(mensagem)
        finally:
            if self._escritor is escritor:
                self._escritor = None
            for futuro in self._pendentes.values():
                if not futuro.done():
                    futuro.set_result({"ok": False, "erro": "a interface foi fechada"})
            self._pendentes.clear()

    def avisar(self, mensagem):
        """Envia sem esperar resposta (ex.: registro novo no histórico)."""
        if self.conectada:
            self._escritor.write((json.dumps(mensagem, ensure_ascii=False) + "\n").encode())

    async def pedir(self, mensagem, tempo=TEMPO_CONFIRMACAO):
        """Envia e espera a resposta do shell. Sem interface ou sem resposta a tempo, devolve ok=False."""
        if not self.conectada:
            return {"ok": False, "erro": "a interface do Terminus não está aberta"}
        identificador = next(self._ids)
        futuro = asyncio.get_running_loop().create_future()
        self._pendentes[identificador] = futuro
        self._escritor.write((json.dumps({"id": identificador, **mensagem}, ensure_ascii=False) + "\n").encode())
        await self._escritor.drain()
        try:
            return await asyncio.wait_for(futuro, tempo)
        except asyncio.TimeoutError:
            self._pendentes.pop(identificador, None)
            self.avisar({"tipo": "cancelar", "id": identificador})
            return {"ok": False, "erro": "sem resposta a tempo"}
