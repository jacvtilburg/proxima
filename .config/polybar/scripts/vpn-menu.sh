
#!/usr/bin/env bash

choice=$(zenity --list \
  --title="Tailscale VPN" \
  --text="Manage your VPN connection" \
  --column="Action" \
  --hide-header \
  --width=320 --height=250 \
  "Show status" "Connect Tailscale" "Disconnect Tailscale")

case "$choice" in
  "Show status")
    zenity --info \
      --title="Tailscale status" \
      --text="$(tailscale status 2>&1)" \
      --width=450
    ;;
  "Connect Tailscale")
    x-terminal-emulator -e bash -lc \
      'sudo tailscale up; echo; read -rp "Press Enter to close..."'
    ;;
  "Disconnect Tailscale")
    x-terminal-emulator -e bash -lc \
      'sudo tailscale down; echo; read -rp "Press Enter to close..."'
    ;;
esac

