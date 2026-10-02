#!/bin/sh
# Остановка hexagonrpcd-adsp-rootpd на время сна (см. audio-sleep):
#  1. /usr/local/sbin/audio-sleep (root) + правила doas без пароля для pre/post
#     (дописываются в /etc/doas.d/60-adsp-fix.conf)
#  2. ~/.config/sxmo/hooks/sxmo_suspend.sh — переопределение штатного, вызывает audio-sleep
#  3. прогон pre/post без сна и проверка звука.
# Откат: ./install-audio-sleep.sh --remove
# Использование: ./install-audio-sleep.sh   (запросит пароль doas)

DIR=$(cd "$(dirname "$0")" && pwd)
ROOT=$DIR/..
CONF=/etc/doas.d/60-adsp-fix.conf
R1='permit nopass :wheel as root cmd /usr/local/sbin/audio-sleep args pre'
R2='permit nopass :wheel as root cmd /usr/local/sbin/audio-sleep args post'
HOOK=~/.config/sxmo/hooks/sxmo_suspend.sh

if [ "$1" = --remove ]; then
	rm -f "$HOOK"
	doas sh -c "grep -v /usr/local/sbin/audio-sleep $CONF > $CONF.new; cat $CONF.new > $CONF; rm -f $CONF.new
		/usr/local/sbin/audio-sleep post; rm -f /usr/local/sbin/audio-sleep"
	echo "[ -- ] эксперимент откатан"
	exit 0
fi

doas sh -c "
install -m755 '$ROOT/system/usr/local/sbin/audio-sleep' /usr/local/sbin/audio-sleep || exit 1
grep -qxF '$R1' $CONF || echo '$R1' >> $CONF
grep -qxF '$R2' $CONF || echo '$R2' >> $CONF
chmod 640 $CONF
" || { echo "[FAIL] установка не удалась"; exit 1; }
echo "[ -- ] audio-sleep установлен"

doas -n /usr/local/sbin/audio-sleep pre || { echo "[FAIL] doas -n audio-sleep pre не прошёл"; exit 1; }
sleep 2
systemctl is-active --quiet hexagonrpcd-adsp-rootpd && echo "[FAIL] rootpd не остановился" || echo "[ OK ] rootpd остановлен"
doas -n /usr/local/sbin/audio-sleep post || { echo "[FAIL] doas -n audio-sleep post не прошёл"; exit 1; }
sleep 2
systemctl is-active --quiet hexagonrpcd-adsp-rootpd && echo "[ OK ] rootpd снова запущен" || echo "[FAIL] rootpd не запустился"

install -m755 "$ROOT/files/.config/sxmo/hooks/sxmo_suspend.sh" "$HOOK"
echo "[ -- ] $HOOK установлен"

exec "$DIR/check-sound.sh" --play
