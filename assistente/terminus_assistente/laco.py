"""O laço do assistente: a pergunta vai para o modelo junto com as ferramentas do MCP; cada ferramenta que ele
pedir é executada pelo servidor do sistema (que pede confirmação ou senha quando o nível manda) e o resultado
volta para o modelo, até ele responder em texto."""

import json
import time

from .mcp import ErroMcp

MAX_PASSOS = 6  # ex.: apps_listar → app_abrir → resposta; mais que isso é o modelo andando em círculo
MAX_RESULTADO = 4000  # caracteres de cada resultado de ferramenta que voltam para o modelo
ESQUECER_APOS = 300  # segundos sem conversa: a próxima pergunta começa do zero
MAX_HISTORICO = 12  # mensagens anteriores mantidas (sem contar as instruções)

DIAS = ["segunda-feira", "terça-feira", "quarta-feira", "quinta-feira", "sexta-feira", "sábado", "domingo"]


def instrucoes(nome):
    # Texto fixo de propósito: as ferramentas vêm logo depois dele no prompt, e qualquer mudança aqui (a hora,
    # por exemplo) faz o llama-server reler tudo a cada pergunta. A hora vai junto da fala do usuário.
    return (f"Você é {nome}, o assistente de voz do Terminus SO, um sistema Linux. Cada fala do usuário vem com "
            "a data e a hora entre colchetes. Responda sempre em português do Brasil, curto e natural, "
            "como numa conversa falada: sem listas, sem markdown, sem emojis. Use as ferramentas para agir no "
            "sistema e para consultar o que não sabe; nunca invente o resultado de uma ação e não ofereça fazer "
            "o que nenhuma ferramenta faz. Se o usuário negar "
            "uma ação ou ela der erro, diga isso com simplicidade. Para abrir um app, descubra o id com "
            "apps_listar antes de usar app_abrir. Caminhos de arquivo começam com ~ para a pasta pessoal "
            "(ex.: ~/Documentos/nota.txt; um arquivo \"da pasta pessoal\" é ~/nome).")


class Assistente:
    def __init__(self, llm, mcp, nome="Terminus"):
        self.llm, self.mcp, self.nome = llm, mcp, nome
        self._historico = []
        self._ultima = 0.0
        self._ferramentas = None

    async def ferramentas(self):
        if self._ferramentas is None:
            self._ferramentas = await self.mcp.ferramentas()
        return self._ferramentas

    def esquecer(self):
        self._historico = []

    async def aquecer(self):
        """Primeiro pedido com as instruções e as ferramentas: o llama-server guarda esse começo em cache e a
        primeira pergunta de verdade não espera ler tudo a frio (dezenas de segundos)."""
        await self.llm.conversar([{"role": "system", "content": instrucoes(self.nome)},
                                  {"role": "user", "content": "oi"}], await self.ferramentas(), max_tokens=1)

    @staticmethod
    def _chamada_escrita(conteudo, ferramentas):
        """Modelos pequenos às vezes escrevem só o nome da ferramenta em vez de chamá-la ("sistema_info"). Se for
        uma ferramenta sem argumentos obrigatórios, vale como a chamada; senão, é texto mesmo."""
        nome = (conteudo or "").strip().strip("`'\".")
        for f in ferramentas:
            if f["function"]["name"] == nome and not f["function"]["parameters"].get("required"):
                return [{"id": "escrita", "type": "function", "function": {"name": nome, "arguments": "{}"}}]
        return []

    async def perguntar(self, texto, ao_agir=lambda nome, argumentos: None):
        """Responde uma pergunta. ao_agir(nome, argumentos) é chamado antes de cada ferramenta (para a tela)."""
        if time.monotonic() - self._ultima > ESQUECER_APOS:
            self._historico = []
        ferramentas = await self.ferramentas()
        agora = time.localtime()
        quando = f"[{DIAS[agora.tm_wday]}, {time.strftime('%d/%m/%Y %H:%M', agora)}]"
        conversa = self._historico + [{"role": "user", "content": f"{quando} {texto}"}]
        acoes = []
        for _ in range(MAX_PASSOS):
            mensagens = [{"role": "system", "content": instrucoes(self.nome)}] + conversa
            resposta = await self.llm.conversar(mensagens, ferramentas)
            chamadas = resposta.get("tool_calls") or self._chamada_escrita(resposta.get("content"), ferramentas)
            if not chamadas:
                final = (resposta.get("content") or "").strip()
                conversa.append({"role": "assistant", "content": final})
                break
            conversa.append({"role": "assistant", "content": resposta.get("content") or "",
                             "tool_calls": chamadas})
            for chamada in chamadas:
                nome = chamada["function"]["name"]
                try:
                    argumentos = json.loads(chamada["function"].get("arguments") or "{}")
                except json.JSONDecodeError:
                    argumentos = {}
                ao_agir(nome, argumentos)
                try:
                    ok, resultado = await self.mcp.chamar(nome, argumentos)
                except ErroMcp as erro:
                    ok, resultado = False, str(erro)
                acoes.append({"ferramenta": nome, "argumentos": argumentos, "ok": ok})
                conversa.append({"role": "tool", "tool_call_id": chamada.get("id", nome),
                                 "content": resultado[:MAX_RESULTADO]})
        else:
            final = "Não consegui terminar isso agora. Pode tentar de outro jeito?"
            conversa.append({"role": "assistant", "content": final})
        self._historico = conversa[-MAX_HISTORICO:]
        # O histórico não pode começar no meio de uma chamada de ferramenta: corta até uma fala do usuário.
        while self._historico and self._historico[0]["role"] != "user":
            self._historico.pop(0)
        self._ultima = time.monotonic()
        return {"texto": final, "acoes": acoes}
