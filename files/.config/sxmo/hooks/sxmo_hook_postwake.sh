#!/bin/sh
# Пользовательский хук sxmo: вызывается после каждого выхода из сна (rtcwake).
# Сначала штатный хук, затем — если ADSP упал при пробуждении — сброс звука в фоне.
# ADSP может упасть уже после вызова хука, поэтому проверка идёт с задержкой.
# Установка: ./install-wake-hook.sh

/usr/share/sxmo/default_hooks/sxmo_hook_postwake.sh "$@"

(
	sleep 6
	if [ "$(cat /sys/class/remoteproc/remoteproc1/state 2>/dev/null)" != running ] ||
		journalctl -k --since '-40sec' --no-pager 2>/dev/null | grep -q 'handling crash'; then
		logger -t sxmo_hook_postwake "ADSP упал при пробуждении, запускаю сброс звука"
		doas -n /usr/local/sbin/adsp-resume-fix post >/dev/null 2>&1
	fi
) >/dev/null 2>&1 &
