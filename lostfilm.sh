#!/bin/bash
# скрипт для автоматической загрузки торрент-файлов новых серий разных сериалов с лостфильма
# обновленная версия

#настройки
DATA_DIR="/home/roma/other/lostfilm"
CONFIG_FILE=$DATA_DIR/lostfilm_config
DBFile=$DATA_DIR/serials.db
TORRENTS_DIR="/home/roma/torrents"
DOWNLOAD_DIR="/home/roma/Downloads"
COMPLETE_DIR="/Data/torrent/complete"
TEMPORARY_DIR="/tmp/lostfilm"
LOG_FILE=$DATA_DIR/lostfilm.log
LOSTFILM_USERID="781443"
LOSTFILM_PASSWD="257cf05a8f0ebef9a07cdef0272190f8"
TORRENT_CLIENT="transmission"

#настройки оповещений
XMPP_REPORT=1
JUICK_REPORT=1
REPORT_JID="antigluk@gmail.com"
LOG=1
#конец настроек

#инициализация
ACTION="DEFAULT"
SERNUM=-1
FAKE=0
FORCE=0
BASEDIRECTORY="`dirname $0`"
#конец инициализации

read_config(){
	IFS=$'\n'
	index=0

	while read line ; do
		name_lines[$index]="`echo "$line" | awk '-F|' '{ print $1 }'`"
		gname_lines[$index]="`echo "$line" | awk '-F|' '{ print $2 }'`"
		url_lines[$index]="`echo "$line" | awk '-F|' '{ print $3 }'`"
		path_lines[$index]="`echo "$line" | awk '-F|' '{ print $4 }' | sed "s/%GNAME%/${gname_lines[$index]}/g"`"
		index=$(($index+1))
	done < $CONFIG_FILE
	return 0
}

read_params(){
	while [ -n "$1" ]; do
		case $1 in
			-a|--action)
				shift
				ACTION="$1"
				;;
			-s|--serial)
				shift
				SERNUM=$(($1-1))
				;;
			-u|--url)
				shift
				PURL=$1
				;;
			--fake)
				FAKE=1
				;;
			--force)
				FORCE=1
				;;
			*)
				fatal_error "Неизвестный параметр $1"
				;;
		esac
		shift
	done
}

echo_serial_info(){
	echo -e "${C_cyan}Название:    ${C_YELLOW}$1${C_NONE}"
	echo -e "${C_cyan}Кодовое имя: ${C_YELLOW}$2${C_NONE}"
	echo -e "${C_cyan}URL:         ${C_YELLOW}$3${C_NONE}"
	echo -e "${C_cyan}Папка:       ${C_YELLOW}$4${C_NONE}"
}

echo_config_info(){
	i=0
	if [ $SERNUM -eq -1 ]; then
		for gname in ${gname_lines[@]}; do
			echo_serial_info ${gname} ${name_lines[$i]} ${url_lines[$i]} ${path_lines[$i]}
			echo -e "${C_CYAN}---------------------------------------------${C_NONE}"
			i=$(($i+1))
		done
	else
		echo_serial_info ${gname_lines[$SERNUM]} ${name_lines[$SERNUM]} ${url_lines[$SERNUM]} ${path_lines[$SERNUM]}
	fi
}

# библиотека для работы с лостфильмом
. $BASEDIRECTORY/lostfilm.lib
# библиотека для работы с базой данных
. $BASEDIRECTORY/db.lib
# библиотека для обработки ошибок
. $BASEDIRECTORY/errors.lib
# библиотека для цветного вывода на терминал
. $BASEDIRECTORY/colors.lib
# библиотека для работы с торрент-клиентом
. $BASEDIRECTORY/btclient.lib

read_params "$@"
read_config

# выполнение действий в соответствии с $ACTION
case $ACTION in
	"PING")
		echo "PONG"
		;;
	"INFO")
		echo_config_info
		;;
	"INITDB")
		init_db
		;;
	"CHECK")
		lostfilm_check
		;;
	"URLEXISTS")
		torrent_exists $PURL
		log_it "$PURL в базе данных 1/0: $?"
		;;
	"PURGE")
		[ $FORCE -eq 1 ] || fatal_error "Для подтверждения очистки базы данных добавте параметр --force"
		if [ $FORCE -eq 1 ]; then
			purge_base "YES, I KNOW WHAT IT IS"
			init_db
		fi
		;;
	"PURGE TORRENTS DIR")
		[ $FORCE -eq 1 ] || fatal_error "Для подтверждения очистки папки торрентов добавте параметр --force"
		if [ $FORCE -eq 1 ]; then
			rm -f ${TORRENTS_DIR}/*.torrent
		fi
		;;
	"CONFIG ADD")
		;;
	"CONFIG REMOVE")
		;;
	"CONFIG LIST")
		;;
	*)
		fatal_error "Неизвестное действие $ACTION"
		;;
esac
