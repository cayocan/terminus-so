"""Catálogo de modelos e download no primeiro uso. Os arquivos vêm dos repositórios oficiais no Hugging Face,
com tamanho e sha256 fixos; um download interrompido continua de onde parou."""

import errno
import hashlib
import json
import shutil
import subprocess
import urllib.request
from dataclasses import dataclass
from pathlib import Path

from . import caminhos


@dataclass(frozen=True)
class Modelo:
    id: str
    nome: str
    arquivo: str
    url: str
    tamanho: int
    sha256: str
    descricao: str

    @property
    def caminho(self):
        return caminhos.MODELOS / self.arquivo

    @property
    def presente(self):
        return self.caminho.exists() and self.caminho.stat().st_size == self.tamanho

    def resumo(self):
        return {"id": self.id, "nome": self.nome, "tamanho": self.tamanho, "descricao": self.descricao,
                "presente": self.presente}


# Avaliação em assistente/README.md e assistente/avaliacao/.
CATALOGO = {m.id: m for m in [
    Modelo("qwen3-8b", "Qwen3 8B", "Qwen3-8B-Q4_K_M.gguf",
           "https://huggingface.co/Qwen/Qwen3-8B-GGUF/resolve/main/Qwen3-8B-Q4_K_M.gguf",
           5027783488, "d98cdcbd03e17ce47681435b5150e34c1417f50b5c0019dd560e4882c5745785",
           "Padrão. Precisa de placa de vídeo com 6 GB ou mais."),
    Modelo("qwen3-1.7b", "Qwen3 1.7B", "Qwen3-1.7B-Q8_0.gguf",
           "https://huggingface.co/Qwen/Qwen3-1.7B-GGUF/resolve/main/Qwen3-1.7B-Q8_0.gguf",
           1834426016, "061b54daade076b5d3362dac252678d17da8c68f07560be70818cace6590cb1a",
           "Leve, para computadores sem placa de vídeo dedicada. Erra mais nas ferramentas."),
]}
PADRAO = "qwen3-8b"
LEVE = "qwen3-1.7b"
VRAM_MINIMA_MIB = 6000
FOLGA = 300 * 1000 * 1000  # espaço que sobra no disco depois do download


class ErroDownload(Exception):
    pass


def gigas(bytes, casas=1):
    """Tamanho em GB com vírgula, como se escreve em português ("1,8")."""
    return f"{bytes / 1e9:.{casas}f}".replace(".", ",")


def memoria_de_video_mib():
    """Maior memória livre entre as placas que o llama.cpp enxerga pelo Vulkan (0 se nenhuma)."""
    try:
        saida = subprocess.run([caminhos.LLAMA_SERVER, "--list-devices"], capture_output=True, text=True,
                               timeout=30).stdout
    except (OSError, subprocess.TimeoutExpired):
        return 0
    # Linhas como "  Vulkan0: Radeon RX 5500 XT (8176 MiB, 7382 MiB free)"
    livres = [int(parte.split()[0]) for linha in saida.splitlines() if "MiB free" in linha
              for parte in [linha.rsplit(",", 1)[-1]]]
    return max(livres, default=0)


def escolhido():
    """Modelo em uso: o que o usuário escolheu, senão o que cabe na placa de vídeo."""
    try:
        id = json.loads(caminhos.ASSISTENTE.read_text(encoding="utf-8")).get("modelo")
        if id in CATALOGO:
            return CATALOGO[id]
    except (OSError, json.JSONDecodeError, AttributeError):
        pass
    return CATALOGO[PADRAO if memoria_de_video_mib() >= VRAM_MINIMA_MIB else LEVE]


def escolher(id):
    if id not in CATALOGO:
        raise ErroDownload(f"modelo desconhecido: {id}")
    caminhos.PESSOAL.mkdir(parents=True, exist_ok=True)
    dados = {}
    try:
        dados = json.loads(caminhos.ASSISTENTE.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        pass
    dados["modelo"] = id
    caminhos.ASSISTENTE.write_text(json.dumps(dados, ensure_ascii=False, indent=1), encoding="utf-8")


def baixar(modelo, progresso=lambda baixado, total: None, cancelado=lambda: False):
    """Baixa para <arquivo>.parte, continuando um download anterior, e só renomeia depois de conferir o sha256."""
    caminhos.MODELOS.mkdir(parents=True, exist_ok=True)
    if modelo.presente:
        return
    parte = modelo.caminho.with_name(modelo.arquivo + ".parte")
    inicio = parte.stat().st_size if parte.exists() else 0
    if inicio > modelo.tamanho:
        parte.unlink()
        inicio = 0
    falta = modelo.tamanho - inicio + FOLGA
    livre = shutil.disk_usage(caminhos.MODELOS).free
    if livre < falta:
        aviso = (f"faltam {gigas(falta - livre)} GB livres em {caminhos.MODELOS} "
                 f"(precisa de {gigas(falta)} GB, tem {gigas(livre)} GB)")
        if Path("/run/live/medium").exists():
            aviso += ". No pendrive (modo live), os arquivos ficam na memória RAM: instale o Terminus para usar o assistente"
        raise ErroDownload(aviso)
    if inicio < modelo.tamanho:
        pedido = urllib.request.Request(modelo.url, headers={"Range": f"bytes={inicio}-"} if inicio else {})
        try:
            with urllib.request.urlopen(pedido, timeout=60) as resposta:
                if inicio and resposta.status != 206:
                    inicio = 0  # o servidor ignorou o Range: começa de novo
                with open(parte, "ab" if inicio else "wb") as arquivo:
                    baixado = inicio
                    while bloco := resposta.read(1 << 20):
                        if cancelado():
                            raise ErroDownload("download cancelado")
                        arquivo.write(bloco)
                        baixado += len(bloco)
                        progresso(baixado, modelo.tamanho)
        except OSError as erro:
            if erro.errno == errno.ENOSPC:
                # Disco cheio: o pedaço baixado só atrapalharia o resto do sistema.
                parte.unlink(missing_ok=True)
            raise ErroDownload(f"falha no download: {erro}") from erro
    if parte.stat().st_size != modelo.tamanho:
        raise ErroDownload("download incompleto; tente de novo para continuar")
    soma = hashlib.sha256()
    with open(parte, "rb") as arquivo:
        while bloco := arquivo.read(8 << 20):
            soma.update(bloco)
    if soma.hexdigest() != modelo.sha256:
        parte.unlink()
        raise ErroDownload("o arquivo baixado não confere (sha256); baixe de novo")
    parte.rename(modelo.caminho)
