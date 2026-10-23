"""Serviço do assistente (terminus-assistente servidor). Sobe o modelo, mantém a conexão com o servidor MCP e
atende o shell num socket local. Mensagens em JSON, uma por linha:

    shell → assistente  {"tipo": "perguntar", "texto": "abre o firefox"}
                        {"tipo": "baixar"}            baixa o modelo escolhido (primeiro uso)
                        {"tipo": "cancelar_download"}
                        {"tipo": "estado"}            pede o estado atual
    assistente → shell  {"tipo": "estado", "esfera": "pensando", "modelo": {...}}
                        {"tipo": "agindo", "ferramenta": "app_abrir", "argumentos": {...}}
                        {"tipo": "resposta", "pergunta": "...", "texto": "...", "acoes": [...]}
"""

import asyncio
import json
import os
import sys

from . import caminhos, modelos
from .laco import Assistente
from .llm import ErroModelo, Llm
from .mcp import ClienteMcp, ErroMcp

# Sem voz ainda (Piper chega depois), a esfera fica "falando" pelo tempo de leitura da resposta.
CARACTERES_POR_SEGUNDO = 15


def nome_do_assistente():
    try:
        return json.loads(caminhos.CONFIGURACOES.read_text(encoding="utf-8")).get("nomeAssistente") or "Terminus"
    except (OSError, json.JSONDecodeError, AttributeError):
        return "Terminus"


class Servico:
    def __init__(self, llm=None):
        self.llm = llm or Llm(os.environ.get("TERMINUS_LLAMA_URL"))
        self.modelo = None
        self.estado_modelo = "verificando"  # ausente, baixando, carregando, pronto, erro
        self.progresso = 0.0
        self.erro = ""
        self.esfera = "repouso"
        self.assistente = None
        self._clientes = set()
        self._trava = asyncio.Lock()
        self._baixando = None
        self._cancelar = False
        self._repouso = None

    # ------------------------------------------------------------ estado para o shell

    def _estado(self):
        modelo = self.modelo.resumo() if self.modelo else {}
        return {"tipo": "estado", "esfera": self.esfera,
                "modelo": {**modelo, "estado": self.estado_modelo, "progresso": round(self.progresso, 3),
                           "erro": self.erro}}

    def _enviar(self, mensagem, para=None):
        linha = (json.dumps(mensagem, ensure_ascii=False) + "\n").encode()
        for escritor in [para] if para else list(self._clientes):
            if not escritor.is_closing():
                escritor.write(linha)

    def _mudar(self, **campos):
        for chave, valor in campos.items():
            setattr(self, chave, valor)
        self._enviar(self._estado())

    def _falar_por(self, texto):
        if self._repouso:
            self._repouso.cancel()
        self._mudar(esfera="falando")

        async def voltar():
            await asyncio.sleep(max(3, len(texto) / CARACTERES_POR_SEGUNDO))
            self._mudar(esfera="repouso")
        self._repouso = asyncio.create_task(voltar())

    # ------------------------------------------------------------ modelo

    async def preparar(self):
        """Escolhe o modelo e, se ele já foi baixado, sobe o llama-server e aquece o cache."""
        self.modelo = await asyncio.to_thread(modelos.escolhido)
        if not self.llm.externo and not self.modelo.presente:
            self._mudar(estado_modelo="ausente")
            return
        self._mudar(estado_modelo="carregando", erro="")
        try:
            await self.llm.iniciar(self.modelo)
            await self._conectar()
            await self.assistente.aquecer()
        except (ErroModelo, ErroMcp) as erro:
            self._mudar(estado_modelo="erro", erro=str(erro))
            return
        self._mudar(estado_modelo="pronto")

    async def _conectar(self):
        nome = nome_do_assistente()
        if self.assistente and self.assistente.nome == nome:
            return
        if self.assistente:
            await self.assistente.mcp.fechar()
        mcp = ClienteMcp(nome)
        await mcp.conectar()
        self.assistente = Assistente(self.llm, mcp, nome)

    def baixar(self):
        if self._baixando and not self._baixando.done():
            return
        self._cancelar = False
        self._baixando = asyncio.create_task(self._baixar())

    async def _baixar(self):
        laco = asyncio.get_running_loop()
        self._mudar(estado_modelo="baixando", progresso=0.0, erro="")
        ultimo = [0.0]

        def progresso(baixado, total):
            fracao = baixado / total
            if fracao - ultimo[0] >= 0.005 or fracao >= 1:  # avisa o shell a cada 0,5%
                ultimo[0] = fracao
                laco.call_soon_threadsafe(lambda: self._mudar(progresso=fracao))
        try:
            await asyncio.to_thread(modelos.baixar, self.modelo, progresso, lambda: self._cancelar)
        except modelos.ErroDownload as erro:
            self._mudar(estado_modelo="ausente", erro=str(erro))
            return
        await self.preparar()

    # ------------------------------------------------------------ perguntas

    async def perguntar(self, texto):
        if self.estado_modelo != "pronto":
            if self.estado_modelo == "ausente":
                aviso = (f"Para conversar, preciso baixar o modelo {self.modelo.nome} "
                         f"({modelos.gigas(self.modelo.tamanho)} GB). É só uma vez.")
            elif self.estado_modelo in ("carregando", "verificando"):
                aviso = "Ainda estou carregando o modelo. Tenta de novo em alguns segundos."
            elif self.estado_modelo == "baixando":
                aviso = f"Ainda estou baixando o modelo ({self.progresso * 100:.0f}%)."
            else:
                aviso = f"O modelo não subiu: {self.erro}"
            return {"tipo": "resposta", "pergunta": texto, "texto": aviso, "acoes": [], "semModelo": True}
        if self._trava.locked():
            return {"tipo": "resposta", "pergunta": texto, "texto": "Um momento, ainda estou na pergunta anterior.",
                    "acoes": []}
        async with self._trava:
            if self._repouso:
                self._repouso.cancel()
            self._mudar(esfera="pensando")
            try:
                await self._conectar()
                agindo = lambda nome, argumentos: self._enviar(
                    {"tipo": "agindo", "ferramenta": nome, "argumentos": argumentos})
                try:
                    resultado = await self.assistente.perguntar(texto, agindo)
                except ErroMcp:
                    # O servidor do sistema pode ter reiniciado: reconecta uma vez.
                    await self.assistente.mcp.fechar()
                    self.assistente = None
                    await self._conectar()
                    resultado = await self.assistente.perguntar(texto, agindo)
            except (ErroModelo, ErroMcp) as erro:
                self._mudar(esfera="erro")
                self._repouso = asyncio.create_task(self._repousar_em(5))
                return {"tipo": "resposta", "pergunta": texto, "texto": f"Algo deu errado: {erro}", "acoes": []}
            self._falar_por(resultado["texto"])
            return {"tipo": "resposta", "pergunta": texto, **resultado}

    async def _responder(self, texto):
        # A resposta vai para todos: o shell mostra mesmo quando a pergunta veio da linha de comando.
        self._enviar(await self.perguntar(texto))

    async def _repousar_em(self, segundos):
        await asyncio.sleep(segundos)
        self._mudar(esfera="repouso")

    # ------------------------------------------------------------ socket do shell

    async def _atender(self, leitor, escritor):
        self._clientes.add(escritor)
        self._enviar(self._estado(), para=escritor)
        try:
            while linha := await leitor.readline():
                try:
                    mensagem = json.loads(linha)
                except json.JSONDecodeError:
                    continue
                tipo = mensagem.get("tipo")
                if tipo == "perguntar" and str(mensagem.get("texto", "")).strip():
                    asyncio.create_task(self._responder(str(mensagem["texto"]).strip()))
                elif tipo == "baixar":
                    if self.estado_modelo == "ausente":
                        self.baixar()
                elif tipo == "cancelar_download":
                    self._cancelar = True
                elif tipo == "estado":
                    self._enviar(self._estado(), para=escritor)
        except ConnectionError:
            pass
        finally:
            self._clientes.discard(escritor)


async def servir():
    servico = Servico()
    caminhos.RUNTIME.mkdir(parents=True, exist_ok=True, mode=0o700)
    if caminhos.SOCKET.exists():
        caminhos.SOCKET.unlink()
    servidor = await asyncio.start_unix_server(servico._atender, path=str(caminhos.SOCKET), limit=1 << 20)
    os.chmod(caminhos.SOCKET, 0o600)
    print(f"terminus-assistente em {caminhos.SOCKET}", file=sys.stderr, flush=True)
    asyncio.create_task(servico.preparar())
    try:
        async with servidor:
            await servidor.serve_forever()
    finally:
        await servico.llm.parar()


async def perguntar_pela_linha_de_comando(texto):
    leitor, escritor = await asyncio.open_unix_connection(str(caminhos.SOCKET), limit=1 << 20)
    escritor.write((json.dumps({"tipo": "perguntar", "texto": texto}, ensure_ascii=False) + "\n").encode())
    await escritor.drain()
    while linha := await leitor.readline():
        mensagem = json.loads(linha)
        if mensagem.get("tipo") == "agindo":
            print(f"  → {mensagem['ferramenta']} {json.dumps(mensagem['argumentos'], ensure_ascii=False)}",
                  file=sys.stderr)
        elif mensagem.get("tipo") == "resposta" and mensagem.get("pergunta") == texto:
            print(mensagem["texto"])
            return 0
    return 1
