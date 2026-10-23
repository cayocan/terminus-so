"""Onde o assistente guarda e encontra as coisas. Tudo do usuário; nada na camada base."""

import os
from pathlib import Path

INICIO = Path.home()
RUNTIME = Path(os.environ.get("XDG_RUNTIME_DIR") or f"/run/user/{os.getuid()}") / "terminus"
SOCKET = RUNTIME / "assistente.sock"
SOCKET_MCP = RUNTIME / "mcp.sock"

DADOS = Path(os.environ.get("XDG_DATA_HOME") or INICIO / ".local/share") / "terminus"
MODELOS = DADOS / "modelos"

PESSOAL = Path(os.environ.get("XDG_CONFIG_HOME") or INICIO / ".config") / "terminus/pessoal"
# Escrito pelo shell (Configurações): nome do assistente, preset, conectores.
CONFIGURACOES = PESSOAL / "configuracoes.json"
# Do assistente: qual modelo usar.
ASSISTENTE = PESSOAL / "assistente.json"

LLAMA_SERVER = os.environ.get("TERMINUS_LLAMA_SERVER", "llama-server")
