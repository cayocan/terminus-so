"""Onde ficam sockets, histórico e preferências do servidor."""

import os
from pathlib import Path

INICIO = Path.home()
RUNTIME = Path(os.environ.get("XDG_RUNTIME_DIR") or f"/run/user/{os.getuid()}") / "terminus"
SOCKET_MCP = RUNTIME / "mcp.sock"
SOCKET_INTERFACE = RUNTIME / "interface.sock"

ESTADO = Path(os.environ.get("XDG_STATE_HOME") or INICIO / ".local/state") / "terminus"
HISTORICO = ESTADO / "historico.jsonl"

# Camada pessoal: nunca sobrescrita pelas atualizações da base.
PESSOAL = Path(os.environ.get("XDG_CONFIG_HOME") or INICIO / ".config") / "terminus/pessoal"
PERMISSOES = PESSOAL / "permissoes.json"
AREAS = PESSOAL / "areas.json"
