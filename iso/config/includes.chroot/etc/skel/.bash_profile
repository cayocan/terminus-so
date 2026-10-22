# Inicia o Hyprland automaticamente no primeiro terminal.
# A tela de login própria do Terminus entra na fase 8.
[ -f ~/.bashrc ] && . ~/.bashrc

# Sem exec: se o Hyprland falhar (por exemplo, numa VM sem aceleração 3D), o usuário fica no
# terminal com um aviso, em vez de o login automático reiniciar tudo num loop de tela preta.
if [ -z "$WAYLAND_DISPLAY" ] && [ "${XDG_VTNR:-0}" = "1" ]; then
	if command -v start-hyprland >/dev/null 2>&1; then
		start-hyprland
	else
		Hyprland
	fi
	status=$?
	clear
	if [ "$status" -ne 0 ]; then
		echo "O Hyprland fechou com erro ($status). Relatórios em ~/.cache/hyprland/."
		echo "Em VM, ele precisa de aceleração 3D. Para tentar de novo: start-hyprland"
	fi
fi
