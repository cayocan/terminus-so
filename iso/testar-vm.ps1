# Testa a ISO do Terminus SO numa VM do VirtualBox (Windows).
#
# Uso (se o PowerShell bloquear scripts: powershell -ExecutionPolicy Bypass -File .\iso\testar-vm.ps1 ...):
#   .\iso\testar-vm.ps1 -Baixar         baixa a ISO da última build do GitHub Actions e liga a VM
#   .\iso\testar-vm.ps1                  usa a ISO mais recente em iso\ e liga a VM
#   .\iso\testar-vm.ps1 -Iso C:\x.iso    usa uma ISO específica
#   .\iso\testar-vm.ps1 -Recriar         apaga a VM de teste (e o disco) e cria de novo
#
# O Hyprland exige aceleração 3D e aborta sem ela, então a VM já sai com o 3D do VirtualBox ligado
# (funciona mesmo com Hyper-V/WSL2/Docker ativos). -Sem3D desliga, para testar só boot e terminal.
#
# Com o Hyper-V ativo, o VirtualBox às vezes não religa a VM depois de desligá-la
# (WHvSetupPartition: ERROR_NO_SYSTEM_RESOURCES); reiniciar o serviço VBoxSVC resolve, e o script faz isso sozinho.
param(
	[string]$Iso,
	[switch]$Baixar,
	[switch]$Recriar,
	[switch]$Sem3D,
	[string]$Nome = "terminus-teste",
	[int]$MemoriaMB = 4096,
	[int]$Cpus = 4,
	[int]$DiscoMB = 32768
)
$ErrorActionPreference = "Stop"

$vbox = Join-Path $env:ProgramFiles "Oracle\VirtualBox\VBoxManage.exe"
if (-not (Test-Path $vbox)) { throw "VirtualBox não encontrado. Instale com: winget install Oracle.VirtualBox" }
function VBox { & $vbox @args; if ($LASTEXITCODE -ne 0) { throw "VBoxManage $($args -join ' ') falhou" } }
# Sem saída e sem parar em erro: no PowerShell 5.1, redirecionar o stderr de um programa com
# ErrorActionPreference=Stop vira erro fatal, e o VBoxManage escreve o progresso no stderr.
function VBoxSilencioso {
	$anterior = $ErrorActionPreference
	$ErrorActionPreference = "Continue"
	& $vbox @args 2>&1 | Out-Null
	$ErrorActionPreference = $anterior
}

$pastaIso = $PSScriptRoot

# A VM ligada prende a ISO antiga; desliga antes de baixar ou trocar a imagem.
if ((& $vbox list runningvms) -match "^`"$Nome`" ") {
	Write-Host "Desligando a VM que estava ligada..."
	VBoxSilencioso controlvm $Nome poweroff
	Start-Sleep -Seconds 3
}

if ($Baixar) {
	$destino = Join-Path $pastaIso "baixada"
	if (Test-Path $destino) { Remove-Item -Recurse -Force $destino }
	Write-Host "Baixando a ISO da última build bem-sucedida..."
	$run = gh run list --workflow build-iso --status success --limit 1 --json databaseId -q ".[0].databaseId"
	if (-not $run) { throw "Nenhuma build bem-sucedida no GitHub Actions ainda." }
	gh run download $run -n terminus-so-iso -D $destino
	if ($LASTEXITCODE -ne 0) { throw "Falha ao baixar o artefato da build $run" }
}

if (-not $Iso) {
	$Iso = Get-ChildItem -Path $pastaIso -Filter *.iso -Recurse | Sort-Object LastWriteTime -Descending |
		Select-Object -First 1 -ExpandProperty FullName
	if (-not $Iso) { throw "Nenhuma ISO em $pastaIso. Use -Baixar ou -Iso <caminho>." }
}
$Iso = (Resolve-Path $Iso).Path
Write-Host "ISO: $Iso"

$existe = (& $vbox list vms) -match "^`"$Nome`" "
if ($existe -and $Recriar) {
	VBox unregistervm $Nome --delete
	$existe = $false
}

if (-not $existe) {
	Write-Host "Criando a VM $Nome..."
	VBox createvm --name $Nome --ostype Debian_64 --register
	$pastaVm = Split-Path ((& $vbox showvminfo $Nome --machinereadable | Select-String '^CfgFile=').ToString().Split('=', 2)[1].Trim('"'))
	# UEFI como no PC real; VMSVGA é o adaptador de vídeo com driver DRM (vmwgfx) no Linux.
	VBox modifyvm $Nome --firmware efi --memory $MemoriaMB --cpus $Cpus `
		--graphicscontroller vmsvga --vram 128 `
		--nic1 nat --audio-driver default --audio-controller hda --audio-enabled on --audio-in on --audio-out on `
		--mouse usbtablet --usb-xhci on --clipboard-mode bidirectional `
		--boot1 dvd --boot2 disk --boot3 none --boot4 none
	VBox storagectl $Nome --name SATA --add sata --controller IntelAhci --portcount 2
	# Disco para testar a instalação pelo Calamares; no modo live ele fica sem uso.
	$disco = Join-Path $pastaVm "$Nome.vdi"
	VBox createmedium disk --filename $disco --size $DiscoMB --format VDI
	VBox storageattach $Nome --storagectl SATA --port 0 --device 0 --type hdd --medium $disco
}

VBox modifyvm $Nome --accelerate-3d $(if ($Sem3D) { "off" } else { "on" })
VBox storageattach $Nome --storagectl SATA --port 1 --device 0 --type dvddrive --medium $Iso
Write-Host "Ligando a VM..."
& $vbox startvm $Nome --type gui
if ($LASTEXITCODE -ne 0) {
	Write-Host "A VM não ligou; reiniciando o serviço do VirtualBox e tentando de novo..."
	Stop-Process -Name VBoxSVC, VBoxSDS -Force -ErrorAction SilentlyContinue
	Start-Sleep -Seconds 4
	VBox startvm $Nome --type gui
}
