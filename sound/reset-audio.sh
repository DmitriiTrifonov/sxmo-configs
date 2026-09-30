#!/bin/sh
# Полный сброс звука на Pixel 3a XL: останавливает PulseAudio и hexagonrpcd,
# отвязывает звуковую карту, кодеки и усилители cs35l36, перезапускает ADSP, затем поднимает всё обратно
# и запускает check-sound.sh.
# Использование: ./reset-audio.sh   (запрашивает doas, нужен терминал)

DIR=$(cd "$(dirname "$0")" && pwd)
RPROC=/sys/class/remoteproc/remoteproc1
AMPS="2-0040 2-0041"
SVCS="hexagonrpcd-adsp-rootpd hexagonrpcd-adsp-sensorspd"

[ "$(cat $RPROC/name 2>/dev/null)" = adsp ] || { echo "remoteproc1 не adsp — стоп"; exit 1; }

# Пользовательская часть: PulseAudio должен быть выключен на время сброса.
# Автозапуск отключаем, иначе любой клиент (pactl из статус-бара) поднимет его снова.
mkdir -p ~/.config/pulse
CONF=~/.config/pulse/client.conf
had_conf=0; [ -e "$CONF" ] && had_conf=1
[ $had_conf -eq 1 ] || printf '# ВРЕМЕННО: создано reset-audio.sh\nautospawn = no\n' > "$CONF"
pulseaudio -k 2>/dev/null
sleep 2
pgrep pulseaudio >/dev/null && { echo "PulseAudio не остановился"; exit 1; }
echo "[ -- ] PulseAudio остановлен"

# Часть с root: отвязать карту и кодеки, перезапустить ADSP, привязать обратно
doas sh -c "
P=/sys/bus/platform
unb() { echo \$2 > \$1/unbind 2>/dev/null; }
bnd() { echo \$2 > \$1/bind 2>/dev/null; }
for s in $SVCS; do systemctl stop \$s; done
unb \$P/drivers/snd-sm8250 sound
for a in $AMPS; do unb /sys/bus/i2c/drivers/cs35l36 \$a; done
unb \$P/drivers/qcom,pm8916-wcd-spmi-codec c440000.spmi:pmic@3:audio-codec@f000
unb \$P/drivers/msm8916-wcd-digital-codec 62ec0000.audio-codec
echo stop > $RPROC/state 2>/dev/null
sleep 3
echo start > $RPROC/state
i=0
while [ \"\$(cat $RPROC/state)\" != running ] && [ \$i -lt 20 ]; do sleep 1; i=\$((i + 1)); done
sleep 5
bnd \$P/drivers/msm8916-wcd-digital-codec 62ec0000.audio-codec
bnd \$P/drivers/qcom,pm8916-wcd-spmi-codec c440000.spmi:pmic@3:audio-codec@f000
for a in $AMPS; do bnd /sys/bus/i2c/drivers/cs35l36 \$a; done
sleep 2
bnd \$P/drivers/snd-sm8250 sound
sleep 3
for s in $SVCS; do systemctl start \$s; done
" || { echo "[FAIL] root-часть не выполнилась"; exit 1; }
echo "[ -- ] ADSP и усилители перезапущены: $(cat $RPROC/state)"

# Вернуть PulseAudio (если конфиг создавали мы — убрать, чтобы автозапуск работал как раньше)
[ $had_conf -eq 1 ] || rm -f "$CONF"
pulseaudio --start --log-target=syslog
sleep 5

exec "$DIR/check-sound.sh" --fix --play
