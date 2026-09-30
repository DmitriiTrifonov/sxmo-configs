#!/bin/sh
# Проверка звука на Pixel 3a XL (postmarketOS).
# Использование: ./check-sound.sh [--fix] [--play]
#   --fix   переключить звук по умолчанию на динамик, снять mute, громкость 70%
#   --play  проиграть тестовый звук

SINK=alsa_output.platform-sound.VoiceCall__Speakers__sink
ADSP=/sys/class/remoteproc/remoteproc1
FIX=0; PLAY=0
for a in "$@"; do
	case $a in
		--fix) FIX=1 ;;
		--play) PLAY=1 ;;
		*) echo "неизвестный аргумент: $a"; exit 2 ;;
	esac
done

rc=0
ok()   { echo "[ OK ] $*"; }
bad()  { echo "[FAIL] $*"; rc=1; }

# 1. ADSP
state=$(cat $ADSP/state 2>/dev/null)
if [ "$state" = running ]; then ok "ADSP: running"; else bad "ADSP: ${state:-неизвестно} (нужен running)"; fi

# 2. Краши ADSP (за последние 2 минуты; всего с загрузки — справочно)
recent=$(journalctl -b -k --since '-2min' --no-pager 2>/dev/null | grep -c 'handling crash')
total=$(journalctl -b -k --no-pager 2>/dev/null | grep -c 'handling crash')
if [ "$recent" -eq 0 ]; then ok "крашей ADSP за 2 минуты: 0 (всего с загрузки: $total)"; else bad "крашей ADSP за 2 минуты: $recent (всего с загрузки: $total)"; fi

# 3. Звуковая карта
if grep -q 'Pixel 3a' /proc/asound/cards; then ok "ALSA-карта Pixel 3a на месте"; else bad "ALSA-карты Pixel 3a нет"; fi

# 4. PulseAudio
if ! pactl info >/dev/null 2>&1; then
	bad "PulseAudio не отвечает (pulseaudio --start)"
	exit 1
fi
if pactl list short sinks | grep -q "$SINK"; then ok "sink динамика существует"; else bad "sink $SINK не найден"; fi

# 5. Sink по умолчанию, mute, громкость
if [ $FIX -eq 1 ]; then
	pactl set-default-sink "$SINK" && pactl set-sink-mute "$SINK" 0 && pactl set-sink-volume "$SINK" 70%
	echo "[ -- ] применён --fix"
fi
def=$(pactl get-default-sink)
if [ "$def" = "$SINK" ]; then ok "sink по умолчанию: динамик"; else bad "sink по умолчанию: $def (запустите с --fix)"; fi
pactl get-sink-mute "$SINK" 2>/dev/null | grep -qE 'yes|да' && bad "звук отключён (mute)" || ok "mute выключен"
echo "       громкость: $(pactl get-sink-volume "$SINK" 2>/dev/null | grep -o '[0-9]*%' | head -1)"

# 6. Тестовое воспроизведение
if [ $PLAY -eq 1 ]; then
	before=$total
	echo "[ -- ] играю тест..."
	timeout 8 speaker-test -D pulse -t wav -c 2 -l 1 >/dev/null 2>&1
	after=$(journalctl -b -k --no-pager 2>/dev/null | grep -c 'handling crash')
	if [ "$after" -gt "$before" ]; then bad "во время теста ADSP упал"; else ok "тест проигран, ADSP не падал (слышно ли — проверьте на слух)"; fi
fi

[ $rc -eq 0 ] && echo "Итог: всё в порядке" || echo "Итог: есть проблемы"
exit $rc
