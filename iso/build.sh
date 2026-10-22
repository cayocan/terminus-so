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

lb config
lb build 2>&1 | tee build.log

ls -lh ./*.iso
