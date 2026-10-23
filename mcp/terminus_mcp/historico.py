"""Histórico de todas as ações pedidas ao servidor, uma por linha (JSON), em ~/.local/state/terminus."""

import json
import time
from collections import deque

from . import caminhos

# Arquivo cresce sem limite? Não: acima disso, guarda só as mais recentes.
MAXIMO_LINHAS = 5000


def registrar(cliente, ferramenta, argumentos, nivel, resultado, detalhe=""):
    """resultado: "feito", "negado" ou "erro"."""
    registro = {
        "quando": time.time(),
        "cliente": cliente,
        "ferramenta": ferramenta,
        "argumentos": _resumir(argumentos),
        "nivel": nivel,
        "resultado": resultado,
        "detalhe": str(detalhe)[:500],
    }
    caminhos.ESTADO.mkdir(parents=True, exist_ok=True)
    with open(caminhos.HISTORICO, "a", encoding="utf-8") as arquivo:
        arquivo.write(json.dumps(registro, ensure_ascii=False) + "\n")
    _podar()
    return registro


def ler(quantidade=50):
    """As ações mais recentes primeiro."""
    if not caminhos.HISTORICO.exists():
        return []
    with open(caminhos.HISTORICO, encoding="utf-8") as arquivo:
        ultimas = deque(arquivo, maxlen=quantidade)
    lista = []
    for linha in reversed(ultimas):
        try:
            lista.append(json.loads(linha))
        except json.JSONDecodeError:
            continue
    return lista


def _resumir(argumentos):
    # Nada de senhas ou textos enormes no histórico.
    resumo = {}
    for chave, valor in (argumentos or {}).items():
        if "senha" in chave.lower():
            continue
        texto = valor if isinstance(valor, (int, float, bool)) else str(valor)
        resumo[chave] = texto[:200] if isinstance(texto, str) else texto
    return resumo


def _podar():
    try:
        with open(caminhos.HISTORICO, encoding="utf-8") as arquivo:
            linhas = arquivo.readlines()
    except OSError:
        return
    if len(linhas) > MAXIMO_LINHAS * 1.2:
        with open(caminhos.HISTORICO, "w", encoding="utf-8") as arquivo:
            arquivo.writelines(linhas[-MAXIMO_LINHAS:])
