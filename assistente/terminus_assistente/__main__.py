"""terminus-assistente servidor | perguntar "texto" | ouvir | dizer "texto" | modelos | escolher <id> | baixar [id]"""

import asyncio
import json
import sys

from . import modelos
from .servidor import dizer_pela_linha_de_comando, ouvir_pela_linha_de_comando, perguntar_pela_linha_de_comando, servir


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
    if comando in ("ouvir", "dizer"):
        if comando == "dizer" and len(argumentos) < 2:
            print(__doc__, file=sys.stderr)
            return 2
        try:
            if comando == "ouvir":
                return asyncio.run(ouvir_pela_linha_de_comando())
            return asyncio.run(dizer_pela_linha_de_comando(" ".join(argumentos[1:])))
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

        # O modelo e, junto, a voz e o ouvido (o que ainda não estiver baixado).
        for arquivo in modelos.pendentes(modelo):
            def progresso(baixado, total, nome=arquivo.nome):
                print(f"\r{nome}: {modelos.gigas(baixado, 2)} de {modelos.gigas(total, 2)} GB", end="",
                      file=sys.stderr)
            try:
                modelos.baixar(arquivo, progresso)
            except modelos.ErroDownload as erro:
                print(f"\n{erro}", file=sys.stderr)
                return 1
            print(f"\n{arquivo.caminho}")
        return 0
    print(__doc__, file=sys.stderr)
    return 2


sys.exit(principal(sys.argv[1:]))
