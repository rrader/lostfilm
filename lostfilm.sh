#!/bin/bash
# скрипт для автоматической загрузки торрент-файлов новых серий разных сериалов с лостфильма
# обновленная версия

#настройки
DATA_DIR="/home/roma/other/lostfilm"
TORRENTS_DIR="/home/roma/torrents/"
DOWNLOAD_DIR="/home/roma/Downloads"
LOG_FILE=$DATA_DIR/lostfilm.log
LOSTFILM_USERID="781443"
LOSTFILM_PASSWD="257cf05a8f0ebef9a07cdef0272190f8"

#настройки оповещений
XMPP_REPORT=1
JUICK_REPORT=1
REPORT_JID="antigluk@gmail.com"
LOG=1
#конец настроек

#инициализация
ACTION="DEFAULT"
#конец инициализации

read_config(){
	return 0
}

read_params(){
	while [ -n "$1" ]; do
		case $1 in
			-a|--action)
				shift
				ACTION="$1"
				;;
			*)
				fatal_error "Неизвестный параметр $1"
				;;
		esac
		shift
	done
}

# библиотека для работы с лостфильмом
. lostfilm.lib
# библиотека для работы с базой данных
. db.lib
# библиотека для обработки ошибок
. errors.lib
# библиотека для цветного вывода на терминал
. colors.lib

read_params $@
read_config

# выполнение действий в соответствии с $ACTION
case $ACTION in
	"PING")
		echo "PONG"
		;;
	"CHECK")
		lostfilm_check
		;;
	*)
		fatal_error "Неизвестное действие $ACTION"
		;;
esac
