#!/bin/sh
# Падал ли ADSP после каждого пробуждения (текущая загрузка).
# «rootpd выкл» — перед этим засыпанием сработал audio-sleep pre (и не был отменён post).
# Использование: ./sleep-stats.sh

journalctl -b --no-pager -o short-iso | awk '
/audio-sleep.*(отвязан|rootpd остановлен) перед сном/ { unb = 1 }
/audio-sleep.*(привязан|rootpd запущен) после сна/ { unb = 0 }
/PM: suspend entry/ { if (t) out(); slept_unb = unb; unb = 0 }
/PM: suspend exit/ { if (t) out(); t = substr($1, 6, 14); sub("T", " ", t); crash = 0 }
/fatal error received/ && t { crash = 1 }
function out() { printf "%s  %-11s  %s\n", t, (slept_unb ? "rootpd выкл" : "-"), (crash ? "КРАШ" : "ok"); s[slept_unb, crash]++; t = "" }
END {
	if (t) out()
	printf "\nбез меры:     %d крашей из %d\n", s[0,1], s[0,0] + s[0,1]
	printf "с мерой:      %d крашей из %d\n", s[1,1], s[1,0] + s[1,1]
}'
