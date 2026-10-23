"""terminus-assistente servidor | perguntar "texto" | modelos | escolher <id> | baixar [id]"""

import asyncio
import json
import sys

from . import modelos
from .servidor import perguntar_pela_linha_de_comando, servir


def principal(argumentos):
    comando = argumentos[0] if argumentos else ""
    if comando == "servidor":
        try:
            asyncio.run(servir())
        except KeyboardInterrupt:
            pass
        return 0
    if comando == "perguntar" and len(argumentos) > 1:
        try:
            return asyncio.run(perguntar_pela_linha_de_comando(" ".join(argumentos[1:])))
        except OSError:
            print("o terminus-assistente não está rodando (systemctl --user start terminus-assistente)",
                  file=sys.stderr)
            return 1
    if comando == "modelos":
        atual = modelos.escolhido()
        print(json.dumps([{**m.resumo(), "escolhido": m.id == atual.id} for m in modelos.CATALOGO.values()],
                         ensure_ascii=False, indent=1))
        return 0
    if comando == "escolher" and len(argumentos) == 2:
        modelos.escolher(argumentos[1])
        print("escolhido; reinicie o serviço: systemctl --user restart terminus-assistente")
        return 0
    if comando == "baixar":
        modelo = modelos.CATALOGO.get(argumentos[1]) if len(argumentos) > 1 else modelos.escolhido()
        if modelo is None:
            print(f"modelo desconhecido: {argumentos[1]}", file=sys.stderr)
            return 1

        def progresso(baixado, total):
            print(f"\r{modelo.nome}: {modelos.gigas(baixado, 2)} de {modelos.gigas(total, 2)} GB", end="", file=sys.stderr)
        try:
            modelos.baixar(modelo, progresso)
        except modelos.ErroDownload as erro:
            print(f"\n{erro}", file=sys.stderr)
            return 1
        print(f"\n{modelo.caminho}")
        return 0
    print(__doc__, file=sys.stderr)
    return 2


sys.exit(principal(sys.argv[1:]))
