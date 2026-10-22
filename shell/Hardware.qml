import QtQuick
import Quickshell.Io

// Leituras de CPU, GPU (AMD) e memória para o widget de hardware, a partir de /proc e /sys.
// Sem GPU AMD (como numa VM), temGpu fica falso e o widget esconde essa parte.
Item {
    id: hardware

    property int intervalo: 2000
    property bool ativo: true

    property string nomeCpu: ""
    property int nucleos: 0
    property real usoCpu: 0
    property real temperaturaCpu: NaN

    property bool temGpu: caminhoGpu !== ""
    property real usoGpu: 0
    property real temperaturaGpu: NaN
    property real vramUsada: 0
    property real vramTotal: 0

    property real memoriaUsada: 0
    property real memoriaTotal: 0

    property string caminhoTempCpu: ""
    property string caminhoGpu: ""
    property string caminhoTempGpu: ""
    property var cpuAnterior: null

    // Descobre uma vez onde ficam os sensores; os caminhos de hwmon e drm mudam entre máquinas.
    Process {
        running: true
        command: ["sh", "-c", `
            for d in /sys/class/hwmon/hwmon*; do
                nome=$(cat "$d/name" 2>/dev/null)
                case "$nome" in
                    k10temp|zenpower|coretemp)
                        # No Ryzen de 1ª geração, temp1 (Tctl) tem um deslocamento; Tdie é a temperatura real.
                        if grep -qs Tdie "$d/temp2_label"; then echo "tempcpu $d/temp2_input"; else echo "tempcpu $d/temp1_input"; fi ;;
                    amdgpu) echo "tempgpu $d/temp1_input" ;;
                esac
            done
            for c in /sys/class/drm/card*/device; do
                [ -f "$c/gpu_busy_percent" ] && echo "gpu $c" && break
            done
            grep -m1 "model name" /proc/cpuinfo
            grep -m1 "cpu cores" /proc/cpuinfo
        `]
        stdout: StdioCollector {
            onStreamFinished: hardware.lerSensores(text)
        }
    }

    function lerSensores(saida) {
        for (const linha of saida.split("\n")) {
            const [chave, ...resto] = linha.split(" ")
            const valor = resto.join(" ")
            if (chave === "tempcpu" && caminhoTempCpu === "") caminhoTempCpu = valor
            else if (chave === "tempgpu" && caminhoTempGpu === "") caminhoTempGpu = valor
            else if (chave === "gpu") caminhoGpu = valor
            else if (linha.startsWith("model name")) nomeCpu = limparNomeCpu(linha.split(":")[1])
            else if (linha.startsWith("cpu cores")) nucleos = parseInt(linha.split(":")[1])
        }
        atualizar()
    }

    function limparNomeCpu(nome) {
        return nome.trim()
            .replace(/^AMD\s+/, "")
            .replace(/^Intel\(R\)\s+Core\(TM\)\s+/, "")
            .replace(/\s+\S+-Core Processor$/, "")
            .replace(/\s+CPU\s+@.*$/, "")
    }

    function lerNumero(arquivo) {
        arquivo.reload()
        const n = parseFloat(arquivo.text())
        return isNaN(n) ? NaN : n
    }

    function atualizar() {
        stat.reload()
        const campos = stat.text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number)
        // ocioso = idle + iowait
        const ocioso = campos[3] + campos[4]
        const total = campos.reduce((a, b) => a + b, 0)
        if (cpuAnterior !== null && total > cpuAnterior.total)
            usoCpu = 100 * (1 - (ocioso - cpuAnterior.ocioso) / (total - cpuAnterior.total))
        cpuAnterior = { ocioso: ocioso, total: total }

        meminfo.reload()
        const mem = {}
        for (const linha of meminfo.text().split("\n")) {
            const partes = linha.split(/:\s+/)
            if (partes.length === 2) mem[partes[0]] = parseInt(partes[1]) * 1024
        }
        memoriaTotal = mem.MemTotal || 0
        memoriaUsada = memoriaTotal - (mem.MemAvailable || 0)

        if (caminhoTempCpu !== "") temperaturaCpu = lerNumero(tempCpu) / 1000
        if (temGpu) {
            usoGpu = lerNumero(gpuOcupada)
            vramUsada = lerNumero(vramUsadaArquivo)
            vramTotal = lerNumero(vramTotalArquivo)
            if (caminhoTempGpu !== "") temperaturaGpu = lerNumero(tempGpu) / 1000
        }
    }

    FileView { id: stat; path: "/proc/stat"; blockLoading: true }
    FileView { id: meminfo; path: "/proc/meminfo"; blockLoading: true }
    FileView { id: tempCpu; path: hardware.caminhoTempCpu; blockLoading: true; printErrors: false }
    FileView { id: tempGpu; path: hardware.caminhoTempGpu; blockLoading: true; printErrors: false }
    FileView { id: gpuOcupada; path: hardware.temGpu ? hardware.caminhoGpu + "/gpu_busy_percent" : ""; blockLoading: true; printErrors: false }
    FileView { id: vramUsadaArquivo; path: hardware.temGpu ? hardware.caminhoGpu + "/mem_info_vram_used" : ""; blockLoading: true; printErrors: false }
    FileView { id: vramTotalArquivo; path: hardware.temGpu ? hardware.caminhoGpu + "/mem_info_vram_total" : ""; blockLoading: true; printErrors: false }

    Timer {
        interval: hardware.intervalo
        repeat: true
        running: hardware.ativo
        onTriggered: hardware.atualizar()
    }
}
