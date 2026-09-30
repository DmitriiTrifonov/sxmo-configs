#!/bin/sh
# Устанавливает сброс звука после сна для sxmo (rtcwake обходит systemd-sleep):
#  1. /usr/local/sbin/adsp-resume-fix (root) + правило doas без пароля только для него
#     (в /etc/doas.d/60-adsp-fix.conf)
#  2. ~/.config/sxmo/hooks/sxmo_hook_postwake.sh (пользовательский хук)
#  3. сразу запускает сброс звука — это и проверка, и восстановление звука.
# Использование: ./install-wake-hook.sh   (запросит пароль doas)

DIR=$(cd "$(dirname "$0")" && pwd)
ROOT=$DIR/..
RULE='permit nopass :wheel as root cmd /usr/local/sbin/adsp-resume-fix args post'

doas sh -c "
mkdir -p /usr/local/sbin
install -m755 '$ROOT/system/usr/local/sbin/adsp-resume-fix' /usr/local/sbin/adsp-resume-fix || exit 1
rm -f /usr/lib/systemd/system-sleep/adsp-resume-fix
# doas.conf перекрывается /etc/doas.d/*.conf (50-sxmo.conf даёт persist) — правило должно идти после него
grep -vxF '$RULE' /etc/doas.conf > /etc/doas.conf.new && cat /etc/doas.conf.new > /etc/doas.conf; rm -f /etc/doas.conf.new
echo '$RULE' > /etc/doas.d/60-adsp-fix.conf
chmod 640 /etc/doas.d/60-adsp-fix.conf
echo '[ -- ] установлено, запускаю сброс звука...'
/usr/local/sbin/adsp-resume-fix post
" || { echo "[FAIL] установка/сброс не удались"; exit 1; }

mkdir -p ~/.config/sxmo/hooks
install -m755 "$ROOT/files/.config/sxmo/hooks/sxmo_hook_postwake.sh" ~/.config/sxmo/hooks/sxmo_hook_postwake.sh
echo "[ -- ] хук sxmo установлен"

sleep 3
exec "$DIR/check-sound.sh" --fix --play
