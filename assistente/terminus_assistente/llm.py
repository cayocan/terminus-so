"""O modelo: um llama-server só para o assistente, escutando apenas no próprio computador, e as conversas
com ele pela API compatível com OpenAI (/v1/chat/completions)."""

import asyncio
import json
import os
import urllib.error
import urllib.request

from . import caminhos

PORTA = int(os.environ.get("TERMINUS_LLAMA_PORTA", "8091"))


class ErroModelo(Exception):
    pass


class Llm:
    def __init__(self, url=None):
        # Com url, usa um llama-server que já está rodando (testes); sem, sobe o próprio.
        self.url = url or f"http://127.0.0.1:{PORTA}"
        self.externo = url is not None
        self._processo = None

    async def iniciar(self, modelo):
        if self.externo:
            return await self._esperar_pronto()
        await self.parar()
        # -ngl 99: tudo na placa de vídeo (sem placa Vulkan, o llama.cpp usa o processador sozinho).
        # --jinja: o modelo de chat do próprio arquivo, que é o que faz as chamadas de ferramenta funcionarem.
        # -np 1: uma conversa por vez, para gastar menos memória.
        # -fa off: com flash attention, a RX 5500 XT lê a pergunta depois das ~2200 tokens das ferramentas 3,5x
        # mais devagar (24 contra 85 tokens/s no llama-bench -d 2300); sem ele, só a geração perde um pouco.
        self._processo = await asyncio.create_subprocess_exec(
            caminhos.LLAMA_SERVER, "-m", str(modelo.caminho), "-ngl", "99", "-c", "8192", "-np", "1",
            "-fa", "off", "--jinja", "--host", "127.0.0.1", "--port", str(PORTA),
            stdin=asyncio.subprocess.DEVNULL, stdout=asyncio.subprocess.DEVNULL,
            stderr=asyncio.subprocess.DEVNULL)
        await self._esperar_pronto()

    async def _esperar_pronto(self, tempo=300):
        # Carregar 5 GB do disco para a placa pode levar um minuto num HD.
        for _ in range(tempo * 2):
            if self._processo is not None and self._processo.returncode is not None:
                raise ErroModelo("o llama-server fechou ao carregar o modelo")
            try:
                with await asyncio.to_thread(urllib.request.urlopen, self.url + "/health", timeout=2) as r:
                    if r.status == 200:
                        return
            except (OSError, urllib.error.HTTPError):
                pass
            await asyncio.sleep(0.5)
        raise ErroModelo("o modelo não ficou pronto a tempo")

    async def parar(self):
        if self._processo is not None and self._processo.returncode is None:
            self._processo.terminate()
            try:
                await asyncio.wait_for(self._processo.wait(), 10)
            except asyncio.TimeoutError:
                self._processo.kill()
        self._processo = None

    async def conversar(self, mensagens, ferramentas=None, max_tokens=600):
        corpo = {"messages": mensagens, "temperature": 0.6, "max_tokens": max_tokens,
                 # Sem o modo de raciocínio do Qwen3: para voz cada segundo conta (assistente/README.md).
                 "chat_template_kwargs": {"enable_thinking": False}}
        if ferramentas:
            corpo["tools"] = ferramentas
        pedido = urllib.request.Request(self.url + "/v1/chat/completions", json.dumps(corpo).encode(),
                                        {"Content-Type": "application/json"})

        def enviar():
            with urllib.request.urlopen(pedido, timeout=300) as resposta:
                return json.load(resposta)
        try:
            resposta = await asyncio.to_thread(enviar)
        except (OSError, ValueError) as erro:
            raise ErroModelo(f"o modelo não respondeu: {erro}") from erro
        return resposta["choices"][0]["message"]
