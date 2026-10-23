"""Ferramentas do sistema, em grupos. Cada uma declara o nível de permissão padrão; "critica" impede que o
usuário a deixe abaixo de senha. As que mexem na tela pedem à interface pelo socket (interface.py)."""

import asyncio
import configparser
import json
import os
import shutil
import socket
import time
from dataclasses import dataclass, field
from pathlib import Path

from . import caminhos, historico
from .permissoes import CONFIRMACAO, LIVRE, SENHA


@dataclass
class Ferramenta:
    nome: str
    grupo: str
    descricao: str
    funcao: object
    nivel: str = LIVRE
    critica: bool = False
    parametros: dict = field(default_factory=dict)
    obrigatorios: list = field(default_factory=list)
    # Texto da confirmação, montado a partir dos argumentos (ex.: "Fechar a janela Firefox").
    resumo: object = None

    def esquema(self):
        return {"type": "object", "properties": self.parametros, "required": self.obrigatorios}


REGISTRO = {}


def ferramenta(nome, grupo, descricao, nivel=LIVRE, critica=False, parametros=None, obrigatorios=None, resumo=None):
    def registrar(funcao):
        REGISTRO[nome] = Ferramenta(nome, grupo, descricao, funcao, nivel, critica,
                                    parametros or {}, obrigatorios or [], resumo)
        return funcao
    return registrar


class ErroFerramenta(Exception):
    """Erro esperado (argumento inválido, app inexistente...): vira resposta de erro, não falha do servidor."""


async def executar(*comando, entrada=None, tempo=20):
    processo = await asyncio.create_subprocess_exec(
        *comando, stdin=asyncio.subprocess.PIPE if entrada else None,
        stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE)
    try:
        saida, erro = await asyncio.wait_for(processo.communicate(entrada), tempo)
    except asyncio.TimeoutError:
        processo.kill()
        raise ErroFerramenta(f"{comando[0]} demorou demais")
    if processo.returncode != 0:
        raise ErroFerramenta(erro.decode(errors="replace").strip() or f"{comando[0]} falhou")
    return saida.decode(errors="replace")


def texto(descricao):
    return {"type": "string", "description": descricao}


def caminho_pessoal(caminho):
    """Caminho dentro da pasta pessoal; ~ é aceito. Fora dela, recusa: o assistente não mexe no sistema por aqui."""
    alvo = Path(os.path.expanduser(caminho)).resolve()
    if alvo != caminhos.INICIO and caminhos.INICIO not in alvo.parents:
        raise ErroFerramenta(f"{alvo} fica fora da pasta pessoal")
    return alvo


# ---------------------------------------------------------------- sistema

@ferramenta("sistema_info", "sistema", "Nome do computador, processador, memória, disco e tempo ligado.")
async def sistema_info(contexto):
    memoria = {}
    for linha in Path("/proc/meminfo").read_text().splitlines():
        chave, _, valor = linha.partition(":")
        memoria[chave] = int(valor.split()[0]) * 1024
    cpu = next((l.split(":", 1)[1].strip() for l in Path("/proc/cpuinfo").read_text().splitlines()
                if l.startswith("model name")), "")
    disco = shutil.disk_usage(caminhos.INICIO)
    return {
        "computador": socket.gethostname(),
        "processador": cpu,
        "nucleos": os.cpu_count(),
        "memoria_total_gb": round(memoria["MemTotal"] / 2**30, 1),
        "memoria_livre_gb": round(memoria["MemAvailable"] / 2**30, 1),
        "disco_livre_gb": round(disco.free / 2**30, 1),
        "ligado_ha_minutos": int(float(Path("/proc/uptime").read_text().split()[0]) // 60),
    }


@ferramenta("volume_ler", "sistema", "Volume da saída de som atual, de 0 a 100, e se está mudo.")
async def volume_ler(contexto):
    saida = await executar("wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@")
    partes = saida.split()
    return {"volume": round(float(partes[1]) * 100), "mudo": "[MUTED]" in saida}


@ferramenta("volume_definir", "sistema", "Muda o volume da saída de som (0 a 100) ou deixa mudo.",
            parametros={"volume": {"type": "integer", "minimum": 0, "maximum": 100},
                        "mudo": {"type": "boolean"}})
async def volume_definir(contexto, volume=None, mudo=None):
    if volume is None and mudo is None:
        raise ErroFerramenta("informe volume ou mudo")
    if volume is not None:
        await executar("wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", f"{max(0, min(100, int(volume)))}%")
    if mudo is not None:
        await executar("wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "1" if mudo else "0")
    return await volume_ler(contexto)


# ---------------------------------------------------------------- apps

def _apps():
    pastas = [caminhos.INICIO / ".local/share/applications", Path("/usr/share/applications"),
              Path("/var/lib/flatpak/exports/share/applications")]
    vistos = {}
    for pasta in pastas:
        for arquivo in sorted(pasta.glob("*.desktop")) if pasta.is_dir() else []:
            if arquivo.stem in vistos:
                continue
            leitor = configparser.ConfigParser(interpolation=None, strict=False)
            try:
                leitor.read(arquivo, encoding="utf-8")
                entrada = leitor["Desktop Entry"]
            except (configparser.Error, KeyError, UnicodeDecodeError):
                continue
            if entrada.get("NoDisplay", "false") == "true" or entrada.get("Type") != "Application":
                continue
            nome = entrada.get("Name[pt_BR]") or entrada.get("Name", arquivo.stem)
            vistos[arquivo.stem] = {"id": arquivo.stem, "nome": nome, "arquivo": str(arquivo),
                                    "descricao": entrada.get("Comment[pt_BR]") or entrada.get("Comment", "")}
    return vistos


@ferramenta("apps_listar", "apps", "Lista os apps instalados (id, nome e descrição). Filtra pelo nome se 'busca' vier.",
            parametros={"busca": texto("parte do nome do app")})
async def apps_listar(contexto, busca=""):
    apps = list(_apps().values())
    if busca:
        apps = [a for a in apps if busca.lower() in (a["nome"] + " " + a["id"]).lower()]
    return [{k: a[k] for k in ("id", "nome", "descricao")} for a in apps]


@ferramenta("app_abrir", "apps", "Abre um app pelo id (veja apps_listar).",
            parametros={"id": texto("id do app, ex.: firefox-esr")}, obrigatorios=["id"])
async def app_abrir(contexto, id):
    app = _apps().get(id)
    if not app:
        raise ErroFerramenta(f"app '{id}' não encontrado")
    # O gio fica preso ao app enquanto ele roda (o foot, por exemplo): solta o processo e só olha se falhou logo.
    processo = await asyncio.create_subprocess_exec(
        "gio", "launch", app["arquivo"], stdin=asyncio.subprocess.DEVNULL,
        stdout=asyncio.subprocess.DEVNULL, stderr=asyncio.subprocess.DEVNULL, start_new_session=True)
    try:
        if await asyncio.wait_for(processo.wait(), 2) != 0:
            raise ErroFerramenta(f"não consegui abrir {app['nome']}")
    except asyncio.TimeoutError:
        pass
    return f"{app['nome']} aberto"


# ---------------------------------------------------------------- janelas

async def _janelas():
    return json.loads(await executar("hyprctl", "clients", "-j"))


@ferramenta("janelas_listar", "janelas", "Lista as janelas abertas (endereço, app, título).")
async def janelas_listar(contexto):
    return [{"endereco": j["address"], "app": j["class"], "titulo": j["title"]} for j in await _janelas()]


@ferramenta("janela_focar", "janelas", "Traz uma janela para a frente pelo endereço (veja janelas_listar).",
            parametros={"endereco": texto("endereço da janela")}, obrigatorios=["endereco"])
async def janela_focar(contexto, endereco):
    await executar("hyprctl", "dispatch", "focuswindow", f"address:{endereco}")
    return "janela em foco"


async def _resumo_janela(endereco):
    try:
        janela = next(j for j in await _janelas() if j["address"] == endereco)
        return f"Fechar a janela “{janela['title']}” ({janela['class']})"
    except (StopIteration, ErroFerramenta, json.JSONDecodeError):
        return f"Fechar a janela {endereco}"


@ferramenta("janela_fechar", "janelas", "Fecha uma janela pelo endereço (o app pode pedir para salvar).",
            nivel=CONFIRMACAO, parametros={"endereco": texto("endereço da janela")}, obrigatorios=["endereco"],
            resumo=lambda a: _resumo_janela(a.get("endereco", "")))
async def janela_fechar(contexto, endereco):
    await executar("hyprctl", "dispatch", "closewindow", f"address:{endereco}")
    return "janela fechada"


# ---------------------------------------------------------------- arquivos

@ferramenta("arquivos_listar", "arquivos", "Lista o conteúdo de uma pasta da pasta pessoal.",
            parametros={"pasta": texto("caminho, ex.: ~/Documentos")})
async def arquivos_listar(contexto, pasta="~"):
    alvo = caminho_pessoal(pasta)
    if not alvo.is_dir():
        raise ErroFerramenta(f"{alvo} não é uma pasta")
    itens = []
    for item in sorted(alvo.iterdir(), key=lambda p: (not p.is_dir(), p.name.lower())):
        if item.name.startswith("."):
            continue
        info = item.stat()
        itens.append({"nome": item.name, "pasta": item.is_dir(), "bytes": info.st_size,
                      "modificado": time.strftime("%Y-%m-%d %H:%M", time.localtime(info.st_mtime))})
    return {"pasta": str(alvo), "itens": itens}


@ferramenta("arquivo_ler", "arquivos", "Lê um arquivo de texto da pasta pessoal (até 64 KB).",
            parametros={"caminho": texto("caminho do arquivo")}, obrigatorios=["caminho"])
async def arquivo_ler(contexto, caminho):
    alvo = caminho_pessoal(caminho)
    if not alvo.is_file():
        raise ErroFerramenta(f"{alvo} não é um arquivo")
    dados = alvo.read_bytes()[:65536]
    if b"\0" in dados:
        raise ErroFerramenta("o arquivo não é de texto")
    return dados.decode(errors="replace")


@ferramenta("pasta_criar", "arquivos", "Cria uma pasta dentro da pasta pessoal.",
            parametros={"caminho": texto("caminho da pasta nova")}, obrigatorios=["caminho"])
async def pasta_criar(contexto, caminho):
    alvo = caminho_pessoal(caminho)
    alvo.mkdir(parents=True, exist_ok=True)
    return f"pasta {alvo} pronta"


@ferramenta("arquivo_mover", "arquivos", "Move ou renomeia um arquivo ou pasta dentro da pasta pessoal. Não sobrescreve.",
            nivel=CONFIRMACAO, parametros={"origem": texto("caminho atual"), "destino": texto("caminho novo")},
            obrigatorios=["origem", "destino"],
            resumo=lambda a: f"Mover {a.get('origem')} para {a.get('destino')}")
async def arquivo_mover(contexto, origem, destino):
    de, para = caminho_pessoal(origem), caminho_pessoal(destino)
    if not de.exists():
        raise ErroFerramenta(f"{de} não existe")
    if para.is_dir():
        para = para / de.name
    if para.exists():
        raise ErroFerramenta(f"{para} já existe")
    shutil.move(str(de), str(para))
    return f"movido para {para}"


@ferramenta("arquivo_lixeira", "arquivos", "Manda um arquivo ou pasta da pasta pessoal para a Lixeira (dá para restaurar).",
            nivel=CONFIRMACAO, parametros={"caminho": texto("caminho")}, obrigatorios=["caminho"],
            resumo=lambda a: f"Mandar {a.get('caminho')} para a Lixeira")
async def arquivo_lixeira(contexto, caminho):
    alvo = caminho_pessoal(caminho)
    if not alvo.exists():
        raise ErroFerramenta(f"{alvo} não existe")
    await executar("gio", "trash", "--", str(alvo))
    return f"{alvo.name} na Lixeira"


# ---------------------------------------------------------------- interface

async def _comando(contexto, acao, **args):
    resposta = await contexto.interface.pedir({"tipo": "comando", "acao": acao, "args": args}, tempo=10)
    if not resposta.get("ok"):
        raise ErroFerramenta(resposta.get("erro", "a interface recusou"))
    return resposta.get("dados", "feito")


@ferramenta("tela_abrir", "interface", "Abre uma tela do Terminus: busca, pastas, configuracoes ou notificacoes.",
            parametros={"tela": {"type": "string", "enum": ["busca", "pastas", "configuracoes", "notificacoes"]},
                        "detalhe": texto("pasta a abrir (pastas) ou categoria (configuracoes)")},
            obrigatorios=["tela"])
async def tela_abrir(contexto, tela, detalhe=""):
    return await _comando(contexto, "abrir", tela=tela, detalhe=detalhe)


@ferramenta("esfera_estado", "interface",
            "Muda o estado da esfera: repouso, escutando, pensando, falando, programando, atencao ou erro.",
            parametros={"estado": {"type": "string", "enum": ["repouso", "escutando", "pensando", "falando",
                                                               "programando", "atencao", "erro"]}},
            obrigatorios=["estado"])
async def esfera_estado(contexto, estado):
    return await _comando(contexto, "esfera", estado=estado)


@ferramenta("cores_definir", "interface", "Troca o preset de cores: Jarvis clássico, Mark ou Stealth.",
            parametros={"preset": {"type": "string", "enum": ["Jarvis clássico", "Mark", "Stealth"]}},
            obrigatorios=["preset"])
async def cores_definir(contexto, preset):
    return await _comando(contexto, "preset", preset=preset)


@ferramenta("avisar", "interface", "Mostra uma notificação para o usuário.",
            parametros={"titulo": texto("título"), "texto": texto("mensagem")}, obrigatorios=["titulo"])
async def avisar(contexto, titulo, texto=""):
    await executar("gdbus", "call", "--session", "--dest", "org.freedesktop.Notifications",
                   "--object-path", "/org/freedesktop/Notifications",
                   "--method", "org.freedesktop.Notifications.Notify",
                   "Terminus", "0", "", titulo, texto, "[]", "{}", "-1")
    return "aviso enviado"


# ---------------------------------------------------------------- áreas de atalho

@ferramenta("areas_listar", "areas", "Lista as áreas de atalho da tela principal, com os atalhos de cada uma.")
async def areas_listar(contexto):
    try:
        areas = json.loads(caminhos.AREAS.read_text(encoding="utf-8")).get("areas", [])
    except (OSError, json.JSONDecodeError):
        return []
    return [{"id": a["id"], "nome": a["nome"], "minimizada": a.get("minimizada", False),
             "atalhos": a.get("atalhos", [])} for a in areas]


@ferramenta("area_criar", "areas", "Cria uma área de atalhos com um nome e, se quiser, apps (ids de apps_listar).",
            parametros={"nome": texto("nome da área"), "apps": {"type": "array", "items": {"type": "string"}}},
            obrigatorios=["nome"])
async def area_criar(contexto, nome, apps=None):
    return await _comando(contexto, "area_criar", nome=nome, apps=apps or [])


@ferramenta("area_minimizar", "areas", "Minimiza ou abre uma área de atalhos pelo nome ou id.",
            parametros={"area": texto("nome ou id da área"), "minimizada": {"type": "boolean"}},
            obrigatorios=["area"])
async def area_minimizar(contexto, area, minimizada=True):
    return await _comando(contexto, "area_minimizar", area=area, minimizada=minimizada)


# ---------------------------------------------------------------- energia

@ferramenta("energia_suspender", "energia", "Suspende o computador.", nivel=CONFIRMACAO,
            resumo=lambda a: "Suspender o computador")
async def energia_suspender(contexto):
    await executar("systemctl", "suspend")
    return "suspendendo"


@ferramenta("energia_reiniciar", "energia", "Reinicia o computador.", nivel=SENHA, critica=True,
            resumo=lambda a: "Reiniciar o computador")
async def energia_reiniciar(contexto):
    await executar("systemctl", "reboot")
    return "reiniciando"


@ferramenta("energia_desligar", "energia", "Desliga o computador.", nivel=SENHA, critica=True,
            resumo=lambda a: "Desligar o computador")
async def energia_desligar(contexto):
    await executar("systemctl", "poweroff")
    return "desligando"


# ---------------------------------------------------------------- histórico

@ferramenta("historico_listar", "historico", "As últimas ações pedidas ao sistema, das mais recentes para as antigas.",
            parametros={"quantidade": {"type": "integer", "minimum": 1, "maximum": 200}})
async def historico_listar(contexto, quantidade=20):
    return historico.ler(int(quantidade))
