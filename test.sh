#!/bin/bash

C_black='\e[0;30m'
C_BLACK='\e[1;30m'
C_red='\e[0;31m'
C_RED='\e[1;31m'
C_green='\e[0;32m'
C_GREEN='\e[1;32m'
C_yellow='\e[0;33m'
C_YELLOW='\e[1;33m'
C_blue='\e[0;34m'
C_BLUE='\e[1;34m'
C_violet='\e[0;35m'
C_VIOLET='\e[1;35m'
C_cyan='\e[0;36m'
C_CYAN='\e[1;36m'
C_white='\e[0;37m'
C_WHITE='\e[1;37m'
C_NONE='\033[0m'
T_UP='\033[1A'

TEST_STR_CMD(){
	echo "-----------------------------------" >> test.log
	[ $VERBOSE -eq 1 ] && echo -e "${C_YELLOW} => ${C_NONE} ${C_WHITE}$3${C_NONE}"
	RET="`$1`"
	if [ "$RET" == "$2" ]; then
		[ $VERBOSE -eq 1 ] && echo -e "${T_UP}${C_YELLOW} ## ${C_NONE}\033[61C${C_GREEN}[PASSED]${C_NONE}"
		echo "=> TEST $3 PASSED" >> test.log
		return 0
	else
		[ $VERBOSE -eq 1 ] && echo -e "${T_UP}${C_YELLOW} ## ${C_NONE}\033[61C${C_RED}[FAIL]${C_NONE}"
		echo "!! TEST $3 FAILED:" >> test.log
		echo $RET >> test.log
		return 1
	fi
}

read_params(){
	while [ -n "$1" ]; do
		case $1 in
			-v)
				VERBOSE=1
				;;
			*)
				;;
		esac
		shift
	done
}

echo "`date` Testing started" > test.log

MARK=0
VERBOSE=0
COUNT=0
MARK=0
read_params $@
#начало тестирования
TEST_STR_CMD "./lostfilm.sh ping" "pong" Ping
MARK=$(($MARK+$?));

if [ $VERBOSE -eq 1 ]; then
	[ $MARK -eq 0 ] && echo -e "${C_WHITE}Test results: $C_GREEN $MARK fails${C_NONE}"
	[ $MARK -eq 0 ] || echo -e "${C_WHITE}Test results: $C_RED $MARK fails${C_NONE}"
else
echo $MARK
fi
echo "===================================" >> test.log
echo "Result: $MARK" >> test.log
