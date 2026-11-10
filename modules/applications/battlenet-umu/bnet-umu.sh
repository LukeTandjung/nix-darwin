declare -r installer_url="https://downloader.battle.net/download/getInstaller?os=win&installer=Battle.net-Setup.exe"

export WINEPREFIX="$BNET_PREFIX"
gamePath="$WINEPREFIX/drive_c/$WIN_PATH"
bnetPath="$WINEPREFIX/drive_c/$BNET_PATH"

# Installation prompts need a terminal even when launched from a desktop entry.
if [ ! -f "$bnetPath" ] || [ ! -f "$gamePath" ]; then
  if [ -z "${UMU_RUNTIME_UPDATE:-}" ]; then
    export UMU_RUNTIME_UPDATE=1
  fi
  if [ ! -t 0 ]; then
    exec xdg-terminal-exec "$0" "$@"
  fi
fi

if [ -z "${UMU_RUNTIME_UPDATE:-}" ]; then
  export UMU_RUNTIME_UPDATE=0
fi

if [ -z "${TZ:-}" ] && [ -r /etc/localtime ]; then
  TZ=$(tail -n 1 /etc/localtime)
  [ -n "$TZ" ] && export TZ
fi

if [ ! -f "$bnetPath" ]; then
  echo "Battle.net is not installed at C:/$BNET_PATH"
  while true; do
    read -rp "Would you like to install it now? [y/n]:" answer
    case $answer in
      [Nn]*) echo "Aborting install"; exit 1 ;;
      [Yy]*) break ;;
    esac
  done

  mkdir -p "$WINEPREFIX/drive_c"
  installer=$(mktemp --suffix=.exe -p "$WINEPREFIX/drive_c")
  trap 'rm -f "$installer"' EXIT

  if ! curl -fL -o "$installer" "$installer_url"; then
    read -rn 1 -p "Download failed [Press any key to exit]"
    exit 1
  fi

  umu-run "$installer"
  rm -f "$installer"
elif [ ! -f "$gamePath" ]; then
  read -rn 1 -p "There is no game installed at $gamePath; install it with Battle.net [Press any key to close]"
  exit 1
else
  umu-run "$gamePath" "$LAUNCH_ARGS"
fi
