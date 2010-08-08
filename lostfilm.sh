#!/bin/bash
#  Автор: Antigluk, Роман Радер [antigluk@gmail.com]
#  http://github.com/antigluk/lostfilm

# скрипт для автоматической загрузки торрент-файлов новых серий разных сериалов с лостфильма
# обновленная версия
BASEDIRECTORY="`dirname $0`"

. $BASEDIRECTORY/config.sh

CONFIG_FILE=$DATA_DIR/lostfilm_config
DBFile=$DATA_DIR/serials.db
LOG_FILE_PATH=$DATA_DIR/lostfilm.log
LOG_FILE="$LOG_FILE_PATH"

#инициализация
ACTION="DEFAULT"
NOANYNOTIFY=0
SERNUM=-1
FAKE=0
FORCE=0

mkdir -p "$TEMPORARY_DIR"
#конец инициализации

# Обрезает строку до нужной длины
# $1 - строка
# $2 - требуемая длина
crop_str(){
	[ ${#1} -gt $2 ] && echo "${1:0:$(($2-3))}..." || echo "$1"
}

while [ -n "$1" ]; do
	case $1 in
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
		# notifications:
		-nan|--no-any-notify)
			NOANYNOTIFY=1
			;;
		--xmpp)
			shift;
			XMPP_REPORT=$1
			;;
		--xmpp-jid)
			shift
			REPORT_JID=$1
			;;
		--juick)
			shift;
			JUICK_REPORT=$1
			;;
		--log)
			shift;
			LOG=$1
			LOG_FILE="$LOG_FILE_PATH"
			;;
		--log-file)
			shift;
			LOG_FILE="$1"
			;;
		# config:
		--data-dir)
			shift;
			DATA_DIR="$1"
			;;
		--torrents-dir)
			shift;
			TORRENTS_DIR="$1"
			;;
		--download-dir)
			shift;
			DOWNLOAD_DIR="$1"
			;;
		--complete-dir)
			shift;
			COMPLETE_DIR="$1"
			;;
		--temporary-dir)
			shift;
			TEMPORARY_DIR="$1"
			;;
		--user-id)
			shift;
			LOSTFILM_USERID="$1"
			;;
		--user-password)
			shift;
			LOSTFILM_PASSWD="$1"
			;;
		--torrent-client)
			shift;
			TORRENT_CLIENT="$1"
			;;
		--config-file)
			shift;
			CONFIG_FILE="$1"
			;;
		--db-file)
			shift;
			DBFile="$1"
			;;
		initdb)
			. $BASEDIRECTORY/db.lib
			init_db
			;;

		*)
			break;
			;;
	esac
	shift
done

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

read_config

while [ -n "$1" ]; do
	case $1 in
		# действия:
		ping)
			echo "pong";
			;;
		info)
			shift;
			params=""
			while [ -n "$1" ]; do
				case $1 in
					about) params="$params --config-info"
					;;
					count) params="$params --db-count"
					;;
					files) params="$params --file-list"
					;;
					config) params="$params --list"
					;;
					*) fatal_error "Неизвестный параметр для info $1"
					;;
				esac
				shift
			done
			[ -z "$params" ] && params="--config-info"
			IFS=' '
			echo_config_info $params
			;;
		c|check)
			lostfilm_check
			;;
		cc|checkcomplete)
			check_complete
			;;
		db)
			shift;
			while [ -n "$1" ]; do
				case $1 in
					remove)
						[ $FORCE -eq 1 ] || fatal_error "Для подтверждения удаления данных добавте параметр --force"
						[ -n "$PURL" ] && db_remove_link $PURL
						[ ! $SERNUM -eq -1 ] && db_remove_serial "${name_lines[$SERNUM]}"
						;;
					exists)
						torrent_exists $PURL
						t_ex=$?
						[ $t_ex -eq 1 ] && log_it "$PURL в базе данных присутствует" || log_it "$PURL в базе данных отсутствует"
						[ $t_ex -eq 1 ] && echo exists || echo not exists;
						;;
					purge)
						[ $FORCE -eq 1 ] || fatal_error "Для подтверждения очистки базы данных добавте параметр --force"
						purge_base "YES, I KNOW WHAT IT IS"
						init_db
						;;
				esac
				shift;
			done
			;;
		config)
			shift;
			while [ -n "$1" ]; do
				case $1 in
					add)
						config_read_serial_info
						echo "$info_fcode|$info_fname|$info_furl|$info_fpath/%GNAME%"
						log_stages 1 "Подтвердите добавление строки в конфиг-файл [y]"
						read x
						[ "x$x" == "xy" ] && config_add_serial "$info_fname" "$info_fcode" "$info_furl" "$info_fpath"\
							&& log_it "Сериал \"$info_fname\" добавлен" ||\
							fatal_error "Добавление сериала \"$info_fname\" прервано";
						;;
					remove)
						[ $SERNUM -eq -1 ] && fatal_error "Укажите номер сериала через опцию -s. Например: lostfilm.sh -s 2 -a \"CONFIG REMOVE\""
						echo_config_info
						log_stages 1 "Удалить список загруженных серий из базы данных? [y/n]"
						read x
						[ "x$x" == "xy" ] && db_remove_serial "${name_lines[$SERNUM]}"
						log_stages 1 "Подтвердите удаление сериала из конфигурации [y]"
						read x
						[ "x$x" == "xy" ] && config_remove_serial $SERNUM
						;;
				esac
				shift;
			done
			;;
		*)
			fatal_error "Неизвестный параметр $1"
			;;
	esac
	shift
done

[ $NOANYNOTIFY -eq 0 ] && send_all_notifies
