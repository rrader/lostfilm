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
# библиотека для работы с конфиг-файлом
. $BASEDIRECTORY/config.lib

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
		config_read_serial_info
		echo "$info_fcode|$info_fname|$info_furl|$info_fpath/%GNAME%"
		log_stages 1 "Подтвердите добавление строки в конфиг-файл [y]"
		read x
		[ "x$x" == "xy" ] && config_add_serial "$info_fname" "$info_fcode" "$info_furl" "$info_fpath"\
		&& log_it "Сериал \"$info_fname\" добавлен" || fatal_error "Добавление сериала \"$info_fname\" прервано";
		;;
	"CONFIG REMOVE")
		[ $SERNUM -eq -1 ] && fatal_error "Укажите номер сериала через опцию -s. Например: lostfilm.sh -s 2 -a \"CONFIG REMOVE\""
		echo_config_info
		log_stages 1 "Подтвердите удаление сериала [y]"
		read x
		[ "x$x" == "xy" ] && config_remove_serial $SERNUM
		;;
	"CONFIG LIST")
		echo_config_info_line
		;;
	*)
		fatal_error "Неизвестное действие $ACTION"
		;;
esac
