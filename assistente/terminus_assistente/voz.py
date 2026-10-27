"""Voz do assistente: falar (Piper tocando pelo PipeWire) e ouvir (microfone pelo PipeWire, transcrição pelo
whisper.cpp). Tudo local.

Os programas podem ser trocados por variáveis de ambiente (os testes usam isso): TERMINUS_PIPER,
TERMINUS_TOCADOR, TERMINUS_GRAVADOR (comandos) e TERMINUS_WHISPER_URL (um whisper-server já rodando)."""

import array
import asyncio
import io
import json
import math
import os
import shlex
import signal
import urllib.request
import uuid
import wave

from . import modelos

TAXA = 16000  # o whisper trabalha com 16 kHz, mono
PORTA_WHISPER = int(os.environ.get("TERMINUS_WHISPER_PORTA", "8092"))
BLOCO = TAXA // 10 * 2  # 100 ms de áudio (16 bits)
SILENCIO_FINAL = 1.2  # segundos de silêncio depois da fala para parar de ouvir
ESPERA_MAXIMA = 6.0  # segundos esperando a pessoa começar a falar
FALA_MAXIMA = 20.0  # segundos no máximo de uma fala
# Textos que o whisper devolve quando não houve fala.
VAZIOS = {"", "[blank_audio]", "(silêncio)", "[silêncio]", "(música)", "[música]", "[ música ]", "legendas pela comunidade amara.org"}


def _comando(variavel, padrao):
    return shlex.split(os.environ[variavel]) if os.environ.get(variavel) else padrao


class ErroVoz(Exception):
    pass


async def _encerrar(processo):
    """Mata o processo e os filhos dele (todos rodam numa sessão própria): um filho que sobrasse seguraria o pipe,
    e o asyncio espera o pipe fechar."""
    if processo.returncode is None:
        try:
            os.killpg(processo.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
    await processo.wait()


# ------------------------------------------------------------ falar

class Boca:
    def __init__(self):
        self._processos = []

    @property
    def falando(self):
        return any(p.returncode is None for p in self._processos)

    async def falar(self, texto):
        """Fala o texto e volta quando terminar (ou quando calar() for chamado)."""
        await self.calar()
        taxa = json.loads(modelos.VOZ_CONFIG.caminho.read_text(encoding="utf-8"))["audio"]["sample_rate"]
        leitura, escrita = os.pipe()
        # O Piper gera o áudio frase por frase; tocando direto da saída dele, a fala começa antes de tudo
        # estar pronto.
        piper = await asyncio.create_subprocess_exec(
            *_comando("TERMINUS_PIPER", ["piper"]), "-m", str(modelos.VOZ.caminho), "--output_raw",
            stdin=asyncio.subprocess.PIPE, stdout=escrita, stderr=asyncio.subprocess.DEVNULL, start_new_session=True)
        tocador = await asyncio.create_subprocess_exec(
            *_comando("TERMINUS_TOCADOR", ["pw-play", "--rate", str(taxa), "--channels", "1", "--format", "s16",
                                           "-"]),
            stdin=leitura, stdout=asyncio.subprocess.DEVNULL, stderr=asyncio.subprocess.DEVNULL, start_new_session=True)
        os.close(leitura)
        os.close(escrita)
        self._processos = [piper, tocador]
        piper.stdin.write(texto.replace("\n", " ").encode() + b"\n")
        await piper.stdin.drain()
        piper.stdin.close()
        await asyncio.gather(piper.wait(), tocador.wait())

    async def calar(self):
        for processo in self._processos:
            await _encerrar(processo)
        self._processos = []


# ------------------------------------------------------------ ouvir

def volume(bloco):
    """Volume (RMS) de um pedaço de áudio de 16 bits."""
    amostras = array.array("h", bloco[: len(bloco) - len(bloco) % 2])
    if not amostras:
        return 0.0
    return math.sqrt(sum(a * a for a in amostras) / len(amostras))


def para_wav(pcm):
    saida = io.BytesIO()
    with wave.open(saida, "wb") as arquivo:
        arquivo.setnchannels(1)
        arquivo.setsampwidth(2)
        arquivo.setframerate(TAXA)
        arquivo.writeframes(pcm)
    return saida.getvalue()


def limpar_transcricao(texto):
    texto = " ".join(texto.split())
    return "" if texto.lower().strip(" .") in VAZIOS else texto


class Ouvido:
    def __init__(self):
        self.url = os.environ.get("TERMINUS_WHISPER_URL")
        self._externo = self.url is not None
        self.url = self.url or f"http://127.0.0.1:{PORTA_WHISPER}"
        self._servidor = None
        self._parar = asyncio.Event()
        self._cancelar = False

    async def iniciar(self):
        """Sobe o whisper-server com o modelo carregado (transcrever fica uma fração do tempo da fala)."""
        if self._externo:
            return
        await self.desligar()
        self._servidor = await asyncio.create_subprocess_exec(
            # Todos os threads e busca gulosa: no Ryzen 7 1800X, 4,5 s por frase com o mesmo acerto (com 8 threads
            # e beam search, 5,9 s). Janela de áudio menor (-ac) acelera, mas erra mais em português.
            "whisper-server", "-m", str(modelos.OUVIDO.caminho), "-l", "pt", "-t", str(os.cpu_count() or 4),
            "-bs", "1", "-bo", "1",
            "--host", "127.0.0.1", "--port", str(PORTA_WHISPER),
            stdin=asyncio.subprocess.DEVNULL, stdout=asyncio.subprocess.DEVNULL, stderr=asyncio.subprocess.DEVNULL)
        for _ in range(120):
            if self._servidor.returncode is not None:
                raise ErroVoz("o whisper-server fechou ao carregar o modelo")
            try:
                with await asyncio.to_thread(urllib.request.urlopen, self.url + "/", timeout=2):
                    return
            except OSError:
                await asyncio.sleep(0.5)
        raise ErroVoz("o reconhecimento de fala não ficou pronto a tempo")

    async def desligar(self):
        if self._servidor is not None and self._servidor.returncode is None:
            self._servidor.terminate()
            await self._servidor.wait()
        self._servidor = None

    def parar(self):
        """Para de ouvir e transcreve o que já foi falado."""
        self._parar.set()

    def cancelar(self):
        """Para de ouvir e descarta (a pessoa preferiu digitar)."""
        self._cancelar = True
        self._parar.set()

    async def ouvir(self):
        """Grava do microfone até a pessoa parar de falar e devolve o texto ("" se não falou nada)."""
        self._parar.clear()
        self._cancelar = False
        gravador = await asyncio.create_subprocess_exec(
            *_comando("TERMINUS_GRAVADOR", ["pw-record", "--rate", str(TAXA), "--channels", "1", "--format", "s16",
                                            "-"]),
            stdin=asyncio.subprocess.DEVNULL, stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.DEVNULL,
            start_new_session=True)
        audio = bytearray()
        try:
            audio = await self._gravar(gravador)
        finally:
            await _encerrar(gravador)
        if self._cancelar or not audio:
            return ""
        return await self.transcrever(bytes(audio))

    async def _gravar(self, gravador):
        audio = bytearray()
        fundo = None  # volume do ambiente, medido no começo
        falou = False
        silencio = 0.0
        tempo = 0.0
        while not self._parar.is_set():
            leitura = asyncio.ensure_future(gravador.stdout.readexactly(BLOCO))
            parada = asyncio.ensure_future(self._parar.wait())
            await asyncio.wait({leitura, parada}, return_when=asyncio.FIRST_COMPLETED)
            parada.cancel()
            if not leitura.done():
                leitura.cancel()
                break
            try:
                bloco = leitura.result()
            except asyncio.IncompleteReadError as fim:
                audio += fim.partial
                break
            audio += bloco
            tempo += 0.1
            nivel = volume(bloco)
            if fundo is None:
                fundo = nivel
            # Fala = bem acima do ruído do ambiente (com um mínimo, para microfone muito limpo).
            limiar = max(fundo * 3, 500)
            if nivel > limiar:
                falou, silencio = True, 0.0
            else:
                silencio += 0.1
                fundo = fundo * 0.95 + nivel * 0.05 if not falou else fundo
            if falou and silencio >= SILENCIO_FINAL:
                break
            if not falou and tempo >= ESPERA_MAXIMA:
                return bytearray()
            if tempo >= FALA_MAXIMA:
                break
        return audio

    async def transcrever(self, pcm):
        """Manda o áudio (16 kHz, mono, 16 bits) para o whisper-server e devolve o texto."""
        fronteira = uuid.uuid4().hex
        partes = []
        for nome, valor in (("language", "pt"), ("response_format", "json"), ("temperature", "0")):
            partes.append(f'--{fronteira}\r\nContent-Disposition: form-data; name="{nome}"\r\n\r\n{valor}\r\n'.encode())
        partes.append(f'--{fronteira}\r\nContent-Disposition: form-data; name="file"; filename="fala.wav"\r\n'
                      f"Content-Type: audio/wav\r\n\r\n".encode() + para_wav(pcm) + b"\r\n")
        partes.append(f"--{fronteira}--\r\n".encode())
        pedido = urllib.request.Request(self.url + "/inference", b"".join(partes),
                                        {"Content-Type": f"multipart/form-data; boundary={fronteira}"})

        def enviar():
            with urllib.request.urlopen(pedido, timeout=120) as resposta:
                return json.load(resposta)
        try:
            resultado = await asyncio.to_thread(enviar)
        except (OSError, ValueError) as erro:
            raise ErroVoz(f"o reconhecimento de fala não respondeu: {erro}") from erro
        return limpar_transcricao(resultado.get("text", ""))
