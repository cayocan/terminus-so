"""Serviço do assistente (terminus-assistente servidor). Sobe o modelo, a voz e o ouvido, mantém a conexão com o
servidor MCP e atende o shell num socket local. Mensagens em JSON, uma por linha:

    shell → assistente  {"tipo": "perguntar", "texto": "abre o firefox"}
                        {"tipo": "ouvir"}             escuta o microfone e pergunta o que ouviu
                        {"tipo": "parar_ouvir"}       para de escutar e usa o que já ouviu
                        {"tipo": "cancelar_ouvir"}    para de escutar e descarta (a pessoa vai digitar)
                        {"tipo": "calar"}             interrompe a fala
                        {"tipo": "falar", "ligado": false}   respostas faladas ou só escritas
                        {"tipo": "dizer", "texto": "..."}    fala um texto (teste da voz)
                        {"tipo": "baixar"}            baixa o que falta (primeiro uso)
                        {"tipo": "cancelar_download"}
                        {"tipo": "estado"}            pede o estado atual
    assistente → shell  {"tipo": "estado", "esfera": "pensando", "modelo": {...}, "voz": {...}}
                        {"tipo": "ouvido", "texto": "abre o firefox"}
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
from .voz import Boca, ErroVoz, Ouvido

# Sem voz (desligada ou ainda não baixada), a esfera fica "falando" pelo tempo de leitura da resposta.
CARACTERES_POR_SEGUNDO = 15


def nome_do_assistente():
    try:
        return json.loads(caminhos.CONFIGURACOES.read_text(encoding="utf-8")).get("nomeAssistente") or "Terminus"
    except (OSError, json.JSONDecodeError, AttributeError):
        return "Terminus"


def _preferencias():
    try:
        dados = json.loads(caminhos.ASSISTENTE.read_text(encoding="utf-8"))
        return dados if isinstance(dados, dict) else {}
    except (OSError, json.JSONDecodeError):
        return {}


def _guardar_preferencia(chave, valor):
    dados = _preferencias()
    dados[chave] = valor
    caminhos.PESSOAL.mkdir(parents=True, exist_ok=True)
    caminhos.ASSISTENTE.write_text(json.dumps(dados, ensure_ascii=False, indent=1), encoding="utf-8")


class Servico:
    def __init__(self, llm=None):
        self.llm = llm or Llm(os.environ.get("TERMINUS_LLAMA_URL"))
        self.boca = Boca()
        self.ouvido = Ouvido()
        self.modelo = None
        self.estado_modelo = "verificando"  # ausente, baixando, carregando, pronto, erro
        self.progresso = 0.0
        self.total_download = 0
        self.erro = ""
        self.esfera = "repouso"
        self.voz_pronta = False
        self.erro_voz = ""
        self.ouvindo = False
        self.baixando_voz = False
        self.falar_ligado = _preferencias().get("falar", True)
        self.assistente = None
        self._clientes = set()
        self._trava = asyncio.Lock()
        self._baixando = None
        self._cancelar = False
        self._repouso = None
        self._fala = None

    # ------------------------------------------------------------ estado para o shell

    def _estado(self):
        modelo = self.modelo.resumo() if self.modelo else {}
        pendente = sum(m.tamanho for m in modelos.pendentes(self.modelo)) if self.modelo else 0
        return {"tipo": "estado", "esfera": self.esfera,
                "modelo": {**modelo, "estado": self.estado_modelo, "progresso": round(self.progresso, 3),
                           "erro": self.erro, "pendente": pendente, "total": self.total_download},
                "voz": {"pronta": self.voz_pronta, "falar": self.falar_ligado, "ouvindo": self.ouvindo,
                        "baixando": self.baixando_voz, "erro": self.erro_voz}}

    def _enviar(self, mensagem, para=None):
        linha = (json.dumps(mensagem, ensure_ascii=False) + "\n").encode()
        for escritor in [para] if para else list(self._clientes):
            if not escritor.is_closing():
                escritor.write(linha)

    def _mudar(self, **campos):
        for chave, valor in campos.items():
            setattr(self, chave, valor)
        self._enviar(self._estado())

    async def _calar(self):
        for tarefa in (self._repouso, self._fala):
            if tarefa and not tarefa.done():
                tarefa.cancel()
        await self.boca.calar()

    def _falar(self, texto):
        """Fala a resposta (ou, sem voz, deixa a esfera falando pelo tempo de leitura) e volta ao repouso."""
        self._mudar(esfera="falando")

        async def falar():
            try:
                if self.voz_pronta and self.falar_ligado:
                    await self.boca.falar(texto)
                else:
                    await asyncio.sleep(max(3, len(texto) / CARACTERES_POR_SEGUNDO))
            except (OSError, ErroVoz, json.JSONDecodeError):
                await asyncio.sleep(max(3, len(texto) / CARACTERES_POR_SEGUNDO))
            self._mudar(esfera="repouso")
        self._fala = asyncio.create_task(falar())

    # ------------------------------------------------------------ modelo e voz

    async def preparar(self):
        """Escolhe o modelo e, se ele já foi baixado, sobe o llama-server, aquece o cache e liga a voz."""
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
        await self._preparar_voz()

    async def _preparar_voz(self):
        if not all(m.presente for m in modelos.VOZ_E_OUVIDO):
            self._mudar(voz_pronta=False, erro_voz="")
            return
        try:
            await self.ouvido.iniciar()
        except (OSError, ErroVoz) as erro:
            self._mudar(voz_pronta=False, erro_voz=str(erro))
            return
        self._mudar(voz_pronta=True, erro_voz="")

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
        """Baixa o que falta (modelo de linguagem, voz e ouvido), com um progresso só para tudo."""
        laco = asyncio.get_running_loop()
        faltam = modelos.pendentes(self.modelo)
        total = sum(m.tamanho for m in faltam) or 1
        self.total_download = total
        sem_modelo = not self.modelo.presente
        if sem_modelo:
            self._mudar(estado_modelo="baixando", progresso=0.0, erro="")
        else:
            self._mudar(progresso=0.0, baixando_voz=True, erro_voz="")
        feito = 0
        ultimo = [0.0]
        for arquivo in faltam:
            def progresso(baixado, _total, antes=feito):
                fracao = (antes + baixado) / total
                if fracao - ultimo[0] >= 0.005 or fracao >= 1:  # avisa o shell a cada 0,5%
                    ultimo[0] = fracao
                    laco.call_soon_threadsafe(lambda: self._mudar(progresso=fracao))
            try:
                await asyncio.to_thread(modelos.baixar, arquivo, progresso, lambda: self._cancelar)
            except modelos.ErroDownload as erro:
                if sem_modelo and not self.modelo.presente:
                    self._mudar(estado_modelo="ausente", erro=str(erro))
                else:
                    # O modelo veio e só a voz falhou: conversa por texto enquanto isso.
                    self._mudar(baixando_voz=False, erro_voz=str(erro))
                    if sem_modelo:
                        await self.preparar()
                return
            feito += arquivo.tamanho
        self.baixando_voz = False
        if sem_modelo:
            await self.preparar()
        else:
            await self._preparar_voz()

    # ------------------------------------------------------------ perguntas

    async def perguntar(self, texto):
        if self.estado_modelo != "pronto":
            if self.estado_modelo == "ausente":
                pendente = sum(m.tamanho for m in modelos.pendentes(self.modelo))
                aviso = (f"Para conversar, preciso baixar o modelo {self.modelo.nome} e a voz "
                         f"({modelos.gigas(pendente)} GB). É só uma vez.")
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
            await self._calar()
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
            self._falar(resultado["texto"])
            return {"tipo": "resposta", "pergunta": texto, **resultado}

    async def _responder(self, texto):
        # A resposta vai para todos: o shell mostra mesmo quando a pergunta veio da linha de comando.
        self._enviar(await self.perguntar(texto))

    async def _ouvir(self):
        if self.ouvindo or self._trava.locked():
            return
        if not self.voz_pronta:
            self._enviar({"tipo": "ouvido", "texto": "", "erro": self.erro_voz or "a voz ainda não foi baixada"})
            return
        await self._calar()
        self._mudar(ouvindo=True, esfera="escutando")
        try:
            texto = await self.ouvido.ouvir()
        except (OSError, ErroVoz) as erro:
            self._mudar(ouvindo=False, esfera="repouso")
            self._enviar({"tipo": "ouvido", "texto": "", "erro": str(erro)})
            return
        self._mudar(ouvindo=False, esfera="repouso" if not texto else "pensando")
        self._enviar({"tipo": "ouvido", "texto": texto})
        if texto:
            await self._responder(texto)

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
                elif tipo == "ouvir":
                    asyncio.create_task(self._ouvir())
                elif tipo == "parar_ouvir":
                    self.ouvido.parar()
                elif tipo == "cancelar_ouvir":
                    self.ouvido.cancelar()
                elif tipo == "calar":
                    await self._calar()
                    self._mudar(esfera="repouso")
                elif tipo == "falar":
                    _guardar_preferencia("falar", bool(mensagem.get("ligado", True)))
                    self._mudar(falar_ligado=bool(mensagem.get("ligado", True)))
                    if not self.falar_ligado:
                        await self.boca.calar()
                elif tipo == "dizer" and str(mensagem.get("texto", "")).strip():
                    await self._calar()
                    self._falar(str(mensagem["texto"]).strip())
                elif tipo == "baixar":
                    if self.modelo and modelos.pendentes(self.modelo) and self.estado_modelo in ("ausente", "pronto"):
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
        await servico.boca.calar()
        await servico.ouvido.desligar()
        await servico.llm.parar()


async def _conversar(mensagem, terminou):
    """Manda uma mensagem ao serviço e imprime o que voltar até terminou(mensagem) ser verdadeiro."""
    leitor, escritor = await asyncio.open_unix_connection(str(caminhos.SOCKET), limit=1 << 20)
    escritor.write((json.dumps(mensagem, ensure_ascii=False) + "\n").encode())
    await escritor.drain()
    while linha := await leitor.readline():
        recebida = json.loads(linha)
        if recebida.get("tipo") == "agindo":
            print(f"  → {recebida['ferramenta']} {json.dumps(recebida['argumentos'], ensure_ascii=False)}",
                  file=sys.stderr)
        elif recebida.get("tipo") == "ouvido":
            print(f"  ouvi: {recebida['texto'] or '(nada)'}" + (f" ({recebida['erro']})" if recebida.get("erro")
                                                                 else ""), file=sys.stderr)
        if terminou(recebida):
            if recebida.get("tipo") == "resposta":
                print(recebida["texto"])
            return 0
    return 1


async def perguntar_pela_linha_de_comando(texto):
    return await _conversar({"tipo": "perguntar", "texto": texto},
                            lambda m: m.get("tipo") == "resposta" and m.get("pergunta") == texto)


async def ouvir_pela_linha_de_comando():
    ouvido = []

    def terminou(m):
        if m.get("tipo") == "ouvido":
            ouvido.append(m["texto"])
            return not m["texto"]
        return m.get("tipo") == "resposta" and bool(ouvido) and m.get("pergunta") == ouvido[0]
    return await _conversar({"tipo": "ouvir"}, terminou)


async def dizer_pela_linha_de_comando(texto):
    vistos = []

    def terminou(m):
        # Termina quando a esfera volta ao repouso depois de falar.
        if m.get("tipo") == "estado":
            vistos.append(m["esfera"])
        return "falando" in vistos and vistos[-1] == "repouso"
    return await _conversar({"tipo": "dizer", "texto": texto}, terminou)
