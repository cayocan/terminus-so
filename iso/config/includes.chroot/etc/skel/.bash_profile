# Inicia o Hyprland automaticamente no primeiro terminal.
# A tela de login própria do Terminus entra na fase 8.
[ -f ~/.bashrc ] && . ~/.bashrc

if [ -z "$WAYLAND_DISPLAY" ] && [ "${XDG_VTNR:-0}" = "1" ]; then
	if command -v start-hyprland >/dev/null 2>&1; then
		exec start-hyprland
	else
		exec Hyprland
	fi
fi
