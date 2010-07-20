#!/bin/bash
# скрипт для автоматической загрузки торрент-файлов новых серий разных сериалов с лостфильма
# обновленная версия

. config.sh

CONFIG_FILE=$DATA_DIR/lostfilm_config
DBFile=$DATA_DIR/serials.db
LOG_FILE_PATH=$DATA_DIR/lostfilm.log
LOG_FILE="$LOG_FILE_PATH"

#инициализация
ACTION="DEFAULT"
SERNUM=-1
FAKE=0
FORCE=0
BASEDIRECTORY="`dirname $0`"

mkdir -p "$TEMPORARY_DIR"
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
			--xmpp)
				XMPP_REPORT=1
				;;
			--no-xmpp)
				XMPP_REPORT=0
				;;
			--xmpp-jid)
				shift
				REPORT_JID=$1
				;;
			--juick)
				JUICK_REPORT=1
				;;
			--no-juick)
				JUICK_REPORT=0
				;;
			--log)
				LOG=1
				LOG_FILE="$LOG_FILE_PATH"
				;;
			--no-log)
				LOG=0
				LOG_FILE="/dev/null"
				;;
			*)
				fatal_error "Неизвестный параметр $1"
				;;
		esac
		shift
	done
}

# Обрезает строку до нужной длины
# $1 - строка
# $2 - требуемая длина
crop_str(){
	[ ${#1} -gt $2 ] && echo "${1:0:$(($2-3))}..." || echo "$1"
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
# библиотека для работы с оповещениями
. $BASEDIRECTORY/notify.lib

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
	"CHECK COMPLETE")
		check_complete
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

send_all_notifies
