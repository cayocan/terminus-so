"""Níveis de permissão: livre, confirmação (por voz quando o assistente existir; por enquanto, um clique)
e senha. Cada ferramenta tem um nível padrão; o usuário pode trocar em ~/.config/terminus/pessoal/permissoes.json,
mas nunca para baixo de "senha" nas ferramentas marcadas como críticas."""

import json
import subprocess

from . import caminhos

LIVRE = "livre"
CONFIRMACAO = "confirmacao"
SENHA = "senha"
NIVEIS = (LIVRE, CONFIRMACAO, SENHA)
ORDEM = {LIVRE: 0, CONFIRMACAO: 1, SENHA: 2}


def nivel_de(ferramenta):
    """Nível valendo para a ferramenta: o pessoal, se houver e for permitido, senão o padrão."""
    escolhido = _pessoais().get(ferramenta.nome)
    if escolhido not in NIVEIS:
        return ferramenta.nivel
    if ferramenta.critica and ORDEM[escolhido] < ORDEM[SENHA]:
        return SENHA
    return escolhido


def _pessoais():
    try:
        dados = json.loads(caminhos.PERMISSOES.read_text(encoding="utf-8"))
        return dados.get("ferramentas", {}) if isinstance(dados, dict) else {}
    except (OSError, json.JSONDecodeError):
        return {}


def senha_confere(senha):
    """Confere a senha do próprio usuário com o unix_chkpwd do PAM (o mesmo que o login usa).
    É o servidor que confere, e não a interface: um programa que se passe pela interface não consegue
    liberar uma ação de senha sem saber a senha."""
    import getpass
    try:
        processo = subprocess.run(
            ["/usr/sbin/unix_chkpwd", getpass.getuser(), "nullok"],
            input=(senha + "\0").encode(), capture_output=True, timeout=10,
        )
    except (OSError, subprocess.TimeoutExpired):
        return False
    return processo.returncode == 0
