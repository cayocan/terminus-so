"""terminus-mcp servidor | stdio | ferramentas"""

import asyncio
import json
import sys

from . import permissoes
from .ferramentas import REGISTRO
from .servidor import ponte_stdio, servir


def main():
    comando = sys.argv[1] if len(sys.argv) > 1 else "servidor"
    if comando == "servidor":
        asyncio.run(servir())
    elif comando == "stdio":
        try:
            asyncio.run(ponte_stdio())
        except (FileNotFoundError, ConnectionRefusedError):
            print("terminus-mcp: o serviço não está rodando (systemctl --user start terminus-mcp)", file=sys.stderr)
            sys.exit(1)
    elif comando == "ferramentas":
        # Para a tela de permissões e para conferência: nome, grupo, nível valendo e se é crítica.
        print(json.dumps([{"nome": f.nome, "grupo": f.grupo, "descricao": f.descricao,
                           "nivel": permissoes.nivel_de(f), "padrao": f.nivel, "critica": f.critica}
                          for f in REGISTRO.values()], ensure_ascii=False, indent=1))
    else:
        print(__doc__, file=sys.stderr)
        sys.exit(2)


if __name__ == "__main__":
    main()
