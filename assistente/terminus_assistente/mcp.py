"""Cliente do servidor MCP do sistema (mcp/terminus_mcp). Tudo que o assistente faz no computador passa por
aqui, com os níveis de permissão e o histórico de lá."""

import asyncio
import itertools
import json

from . import caminhos, VERSAO

# Uma ferramenta de confirmação ou senha espera o usuário responder na tela (até 60 s no servidor).
TEMPO_FERRAMENTA = 120


class ErroMcp(Exception):
    pass


class ClienteMcp:
    def __init__(self, nome):
        self.nome = nome
        self._leitor = self._escritor = None
        self._ids = itertools.count(1)
        self._trava = asyncio.Lock()

    async def conectar(self):
        try:
            self._leitor, self._escritor = await asyncio.open_unix_connection(str(caminhos.SOCKET_MCP),
                                                                              limit=1 << 22)
        except OSError as erro:
            raise ErroMcp("o servidor do sistema (terminus-mcp) não está rodando") from erro
        await self._pedir("initialize", {"protocolVersion": "2025-06-18", "capabilities": {},
                                         "clientInfo": {"name": self.nome, "version": VERSAO}})
        self._escritor.write(b'{"jsonrpc": "2.0", "method": "notifications/initialized"}\n')

    async def fechar(self):
        if self._escritor:
            self._escritor.close()
        self._leitor = self._escritor = None

    async def _pedir(self, metodo, parametros, tempo=30):
        async with self._trava:
            if self._escritor is None or self._escritor.is_closing():
                raise ErroMcp("sem conexão com o servidor do sistema")
            identificador = next(self._ids)
            self._escritor.write((json.dumps({"jsonrpc": "2.0", "id": identificador, "method": metodo,
                                              "params": parametros}) + "\n").encode())
            await self._escritor.drain()
            try:
                while True:
                    linha = await asyncio.wait_for(self._leitor.readline(), tempo)
                    if not linha:
                        raise ErroMcp("o servidor do sistema fechou a conexão")
                    mensagem = json.loads(linha)
                    if mensagem.get("id") == identificador:
                        break
            except asyncio.TimeoutError as erro:
                raise ErroMcp("o servidor do sistema não respondeu a tempo") from erro
        if "error" in mensagem:
            raise ErroMcp(mensagem["error"].get("message", "erro no servidor do sistema"))
        return mensagem["result"]

    async def ferramentas(self):
        """No formato de ferramentas da API de chat (o que o llama-server espera)."""
        resultado = await self._pedir("tools/list", {})
        return [{"type": "function", "function": {"name": f["name"], "description": f.get("description", ""),
                                                  "parameters": f.get("inputSchema", {"type": "object"})}}
                for f in resultado["tools"]]

    async def chamar(self, nome, argumentos):
        """Devolve (deu_certo, texto). Negado pelo usuário ou erro da ferramenta volta como texto, para o modelo
        poder contar ao usuário o que aconteceu."""
        resultado = await self._pedir("tools/call", {"name": nome, "arguments": argumentos}, TEMPO_FERRAMENTA)
        texto = "\n".join(c.get("text", "") for c in resultado.get("content", []) if c.get("type") == "text")
        return not resultado.get("isError"), texto
