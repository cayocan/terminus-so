"""Servidor MCP (JSON-RPC 2.0, uma mensagem por linha) num socket local. Cada conexão é uma sessão de um
cliente: o assistente local ou uma IA de programação. Toda chamada de ferramenta passa pela permissão e
vai para o histórico."""

import asyncio
import inspect
import json
import os
import sys

from . import VERSAO, caminhos, historico, permissoes
from .ferramentas import REGISTRO, ErroFerramenta
from .interface import Interface

VERSOES_PROTOCOLO = ("2025-06-18", "2025-03-26", "2024-11-05")


class Contexto:
    def __init__(self, interface):
        self.interface = interface


class Sessao:
    def __init__(self, contexto):
        self.contexto = contexto
        self.cliente = "desconhecido"

    async def tratar(self, mensagem):
        """Devolve a resposta (dict) ou None para notificações."""
        metodo = mensagem.get("method")
        identificador = mensagem.get("id")
        if identificador is None:
            return None  # notificação (ex.: notifications/initialized)
        try:
            resultado = await self._metodo(metodo, mensagem.get("params") or {})
            return {"jsonrpc": "2.0", "id": identificador, "result": resultado}
        except ErroProtocolo as erro:
            return {"jsonrpc": "2.0", "id": identificador, "error": {"code": erro.codigo, "message": str(erro)}}

    async def _metodo(self, metodo, parametros):
        if metodo == "initialize":
            info = parametros.get("clientInfo") or {}
            self.cliente = info.get("name", "desconhecido")
            pedida = parametros.get("protocolVersion")
            return {
                "protocolVersion": pedida if pedida in VERSOES_PROTOCOLO else VERSOES_PROTOCOLO[0],
                "capabilities": {"tools": {"listChanged": False}},
                "serverInfo": {"name": "terminus", "version": VERSAO},
                "instructions": ("Ferramentas do Terminus SO. Algumas pedem confirmação ou senha do usuário "
                                 "antes de rodar; se ele negar, a ferramenta devolve erro e não faz nada."),
            }
        if metodo == "ping":
            return {}
        if metodo == "tools/list":
            return {"tools": [self._descrever(f) for f in REGISTRO.values()]}
        if metodo == "tools/call":
            return await self._chamar(parametros.get("name"), parametros.get("arguments") or {})
        raise ErroProtocolo(-32601, f"método desconhecido: {metodo}")

    def _descrever(self, ferramenta):
        nivel = permissoes.nivel_de(ferramenta)
        aviso = {"confirmacao": " Pede confirmação do usuário.", "senha": " Pede a senha do usuário."}.get(nivel, "")
        return {"name": ferramenta.nome, "description": ferramenta.descricao + aviso,
                "inputSchema": ferramenta.esquema(),
                "annotations": {"readOnlyHint": ferramenta.nome.endswith(("_listar", "_ler", "_info"))}}

    async def _chamar(self, nome, argumentos):
        ferramenta = REGISTRO.get(nome)
        if not ferramenta:
            raise ErroProtocolo(-32602, f"ferramenta desconhecida: {nome}")
        nivel = permissoes.nivel_de(ferramenta)
        interface = self.contexto.interface

        if nivel != permissoes.LIVRE:
            resumo = ferramenta.resumo(argumentos) if ferramenta.resumo else ferramenta.descricao
            if inspect.isawaitable(resumo):
                resumo = await resumo
            resposta = await interface.pedir({"tipo": "confirmar", "nivel": nivel, "ferramenta": nome,
                                              "cliente": self.cliente, "resumo": resumo})
            liberado = resposta.get("ok") and (nivel != permissoes.SENHA or
                                               await asyncio.to_thread(permissoes.senha_confere,
                                                                       resposta.get("senha", "")))
            if not liberado:
                motivo = resposta.get("erro") or ("senha incorreta" if resposta.get("ok") else "o usuário negou")
                self._registrar(nome, argumentos, nivel, "negado", motivo)
                return _resultado(f"Não feito: {motivo}.", erro=True)

        try:
            valor = await ferramenta.funcao(self.contexto, **argumentos)
        except ErroFerramenta as erro:
            self._registrar(nome, argumentos, nivel, "erro", erro)
            return _resultado(str(erro), erro=True)
        except TypeError as erro:
            self._registrar(nome, argumentos, nivel, "erro", erro)
            return _resultado(f"argumentos inválidos: {erro}", erro=True)
        except Exception as erro:  # o servidor não pode cair por causa de uma ferramenta
            self._registrar(nome, argumentos, nivel, "erro", repr(erro))
            return _resultado(f"falha inesperada: {erro!r}", erro=True)
        self._registrar(nome, argumentos, nivel, "feito", valor if isinstance(valor, str) else "")
        return _resultado(valor)

    def _registrar(self, nome, argumentos, nivel, resultado, detalhe):
        registro = historico.registrar(self.cliente, nome, argumentos, nivel, resultado, detalhe)
        self.contexto.interface.avisar({"tipo": "historico", "registro": registro})


class ErroProtocolo(Exception):
    def __init__(self, codigo, mensagem):
        super().__init__(mensagem)
        self.codigo = codigo


def _resultado(valor, erro=False):
    corpo = valor if isinstance(valor, str) else json.dumps(valor, ensure_ascii=False, indent=1)
    resultado = {"content": [{"type": "text", "text": corpo}], "isError": erro}
    if isinstance(valor, dict):
        resultado["structuredContent"] = valor
    return resultado


async def _atender_cliente(contexto, leitor, escritor):
    sessao = Sessao(contexto)
    try:
        while linha := await leitor.readline():
            try:
                mensagem = json.loads(linha)
            except json.JSONDecodeError:
                resposta = {"jsonrpc": "2.0", "id": None, "error": {"code": -32700, "message": "JSON inválido"}}
            else:
                resposta = await sessao.tratar(mensagem)
            if resposta is not None:
                escritor.write((json.dumps(resposta, ensure_ascii=False) + "\n").encode())
                await escritor.drain()
    except (ConnectionResetError, BrokenPipeError):
        pass
    finally:
        escritor.close()


async def servir():
    interface = Interface()
    contexto = Contexto(interface)
    servidor_interface = await interface.iniciar()
    if caminhos.SOCKET_MCP.exists():
        caminhos.SOCKET_MCP.unlink()
    servidor_mcp = await asyncio.start_unix_server(
        lambda l, e: _atender_cliente(contexto, l, e), path=str(caminhos.SOCKET_MCP))
    os.chmod(caminhos.SOCKET_MCP, 0o600)
    print(f"terminus-mcp {VERSAO}: {len(REGISTRO)} ferramentas em {caminhos.SOCKET_MCP}", file=sys.stderr, flush=True)
    async with servidor_interface, servidor_mcp:
        await asyncio.gather(servidor_interface.serve_forever(), servidor_mcp.serve_forever())


async def ponte_stdio():
    """Liga stdin/stdout ao socket do servidor, para clientes que só iniciam servidores MCP por stdio
    (ex.: claude mcp add terminus -- terminus-mcp stdio)."""
    leitor_sock, escritor_sock = await asyncio.open_unix_connection(str(caminhos.SOCKET_MCP))
    laco = asyncio.get_running_loop()
    leitor_stdin = asyncio.StreamReader()
    await laco.connect_read_pipe(lambda: asyncio.StreamReaderProtocol(leitor_stdin), sys.stdin)

    async def subir():
        while linha := await leitor_stdin.readline():
            escritor_sock.write(linha)
            await escritor_sock.drain()
        # Fecha só a ida: as respostas que faltam ainda precisam voltar.
        escritor_sock.write_eof()

    async def descer():
        while linha := await leitor_sock.readline():
            sys.stdout.buffer.write(linha)
            sys.stdout.buffer.flush()

    await asyncio.gather(subir(), descer())
