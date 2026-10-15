
#!/usr/bin/env bash

choice=$(zenity --list \
  --title="Power menu" \
  --text="What would you like to do?" \
  --column="Action" \
  --hide-header \
  --width=300 --height=300 \
  "Lock screen" "Suspend" "Log out" "Restart" "Shut down")

case "$choice" in
  "Lock screen") cinnamon-screensaver-command -l ;;
  "Suspend") systemctl suspend ;;
  "Log out") cinnamon-session-quit --logout ;;
  "Restart") cinnamon-session-quit --reboot ;;
  "Shut down") cinnamon-session-quit --power-off ;;
esac

