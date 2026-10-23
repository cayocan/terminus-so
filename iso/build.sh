#!/bin/sh
# Gera a ISO do Terminus SO. Rodar como root num Debian 13 com live-build instalado.
set -e

cd "$(dirname "$0")"

if [ "$(id -u)" -ne 0 ]; then
	echo "Rode como root: sudo ./build.sh" >&2
	exit 1
fi

lb clean

mkdir -p config/includes.chroot/usr/share/terminus
cp -r ../shell config/includes.chroot/usr/share/terminus/shell
mkdir -p config/includes.chroot/usr/lib/terminus/mcp
cp -r ../mcp/terminus_mcp config/includes.chroot/usr/lib/terminus/mcp/terminus_mcp
mkdir -p config/includes.chroot/usr/lib/terminus/assistente
cp -r ../assistente/terminus_assistente config/includes.chroot/usr/lib/terminus/assistente/terminus_assistente

lb config
# O tee esconde o código de saída do lb build; guarda-o num arquivo para o set -e não deixar passar falha.
{ lb build 2>&1; echo $? > build.status; } | tee build.log
[ "$(cat build.status)" -eq 0 ] || { echo "lb build falhou; veja iso/build.log" >&2; exit 1; }

ls -lh ./*.iso
