#!/bin/bash
##### WORDPRESS VARIABLES
DOMAIN_NAME='dev.wordpress.com'
BLOG_TITLE='WordPress'
BLOG_DESCRIPTION="Just another WordPress site"
WP_USER='admin'
#WP_USER_PASSWORD='password'
WP_USER_EMAIL='ash@email.com'


##### SETUP DIRECTORIES NAME
SOURCE_DIR='wordpress'
# CURRENT_PATH=$(pwd)
# SCRIPT_PATH=$(dirname "$($READLINK -f "$0")")
# ROOT_PATH=$($READLINK -f "$SCRIPT_DIR/../../")
# SOURCE_PATH=$($READLINK -f "$CURRENT_DIR/$SOURCE_DIR")


##### COLOR VARIABLES
red=$'\e[31m'
green=$'\e[32m'
yellow=$'\e[33m'
cyan=$'\e[36m'
purple=$'\e[35m'
reset=$'\e[0m'
bold=$'\e[1m'


##### UTILITIES FUNCTIONS
output() {
	case "$2" in
		-e)
			OUTPUT="$bold$red$1$reset";;
		-s)
			OUTPUT="$bold$green$1$reset";;
		-w)
			OUTPUT="$bold$yellow$1$reset";;
		-i)
			OUTPUT="$bold$cyan$1$reset";;
		*)
			OUTPUT="$reset$1";;
	esac
	echo -e $OUTPUT
}

input() {
	read -p "$bold$cyan> $*$reset" INPUT_VALUE
	echo $INPUT_VALUE
}

confirm_to_continue() {
	CONTINUE=$(input "$*")
	if [[ ! "$CONTINUE" =~ ^([yY][eE][sS]|[yY])+$ ]]
	then
		output "Canceled." -e && exit 1
	fi
}

check_command_exists() {
	# usage: check_command_exists <check_command_ouput> <message_if_not_found>
	# $1 2>&1 >/dev/null
	$1 2>/dev/null
	CMD_IS_AVAILABLE=$?

	if [ ! $CMD_IS_AVAILABLE -eq 0 ]; then
		output "$2" -e
		exit 1
	fi
}

check_depedencies() {
	output "# Checking depedencies..." -i
	# check_command_exists "git --version" "Git is not found. Please install git first."
	check_command_exists "docker --version" "Docker is not found. Please install docker first."
	check_command_exists "docker-compose --version" "Docker Compose is not found. Please install docker-compose first."
	# check_command_exists "php -v" "PHP is not found. Please install PHP first."
}

prepare_empty_dir() {
	output "# Preparing target directory..." -i
	target="$1"
	if [ ! -z "$(ls -A $target)" ]; then
		backup="$1.bak"
    if [[ -e "$backup" ]]
    then
        count=0
        while [[ -e "$backup.$count" ]]; do let "count += 1"; done
        backup="$backup.$count"
    fi
    mv "$target" "$backup"
    output "   existing folder was renamed to \"$backup\"."
	fi
	mkdir -p "$target"
}

check_empty_dir() {
	output "# Checking install folder..." -i
	target="$1"
	if [ ! -z "$(ls -A $target)" ]; then
		output "$2" -e && exit 1
	fi
}


#### CHECK REQUIRED COMMANDS

READLINK='readlink'
unamestr=`uname`
if [ "$unamestr" == 'FreeBSD' -o "$unamestr" == 'Darwin'  ]; then
  READLINK='greadlink'
fi

if [ -z "`which $READLINK`" ]; then
    output "[ERROR] $READLINK not installed" -e
    output "        make sure coreutils are installed" -e
    output "        MacOS: brew install coreutils" -e
    exit 1
fi
