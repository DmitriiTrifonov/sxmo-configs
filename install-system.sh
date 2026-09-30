#!/bin/sh
# Устанавливает системную часть (нужен root): powerplan и фикс звука ADSP.
# Пользовательская часть (~/.local/bin/powerplan, хуки, userscripts) ставится ./restore.sh
# Звук + правило doas: sound/install-wake-hook.sh
set -e
SRC="$(cd "$(dirname "$0")" && pwd)/system"
cd "$SRC"
doas sh -c "
cd '$SRC'
find . -type f | while read -r f; do
  mkdir -p \"/\$(dirname \"\$f\")\"
  install -m755 \"\$f\" \"/\$f\"
  echo \"installed /\$f\"
done
"
