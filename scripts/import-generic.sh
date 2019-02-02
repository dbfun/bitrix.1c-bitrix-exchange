#!/bin/bash

#
# Ссылки
#

# скрипт обмена по HTTP
URI="$SITE/bitrix/admin/1c_exchange.php"
# авторизация
URI_CHECKAUTH="$URI?type=catalog&mode=checkauth"
# инициация
URI_INIT="$URI?type=catalog&mode=init"
# загрузка файла
URI_UPLOAD="$URI?type=catalog&mode=file&filename=$FILE_NAME"

#
# Служебные переменные
#

# Импорт осуществляется из этого файла, который монтируется с хоста
SRC_FILE="/src"
# Файл кукисов
COOK="/var/log/cookiefile.txt"
# Продолжить обработку
STEP_CONTINUE=1
# Уровень "молчания" curl: "показывать только ошибки, скрыть прогресс бар"
CURL_VERBOSITY="-sS"


source lib/colors.sh
# assert, info, ok, warning, error:
source lib/functions.sh

function checkauth {
  info "checkauth:\t$URI_CHECKAUTH"
  curl $CURL_VERBOSITY -c $COOK $URI_CHECKAUTH --user "$AUTH_LOGIN":"$AUTH_PASS" --trace-ascii /var/log/curl-debug.txt > /var/log/01-checkauth.txt
  assert "$?" "0" "Login fails"
}

function init {
  info "init:\t\t$URI_INIT"
  curl $CURL_VERBOSITY -c $COOK -b $COOK $URI_INIT --user "$AUTH_LOGIN":"$AUTH_PASS" --trace-ascii /var/log/curl-debug.txt > /var/log/02-init.txt
  assert "$?" "0" "Init fails"
}

function upload {
  info "upload file:\t$URI_UPLOAD"
  curl $CURL_VERBOSITY -c $COOK -b $COOK -X POST --data-binary @- $URI_UPLOAD --user "$AUTH_LOGIN":"$AUTH_PASS" -H "Content-Type: application/octet-stream" -H "Expect:" --trace-ascii /var/log/curl-debug.txt < $SRC_FILE > /var/log/03-file.txt
  assert "$?" "0" "File upload fails"
}

function step {
  curl $CURL_VERBOSITY -c $COOK -b $COOK $URI_STEP --user "$AUTH_LOGIN":"$AUTH_PASS" --trace-ascii /var/log/curl-debug.txt > /var/log/step.txt
  assert "$?" "0" "Progress file fails (curl error)"

  echo
  iconv -f $CHARSET_IN -t $CHARSET_OUT /var/log/step.txt
  echo

  if grep -q failure /var/log/step.txt ; then
    error "Progress file fails (error in response)"
    exit 1
  fi

  if grep -q progress /var/log/step.txt ; then
    STEP_CONTINUE=1
  else
    STEP_CONTINUE=0
  fi
}

# обработка единичного файла
function process {
  URI_STEP="$URI?type=catalog&mode=$GET_STEP_MODE&filename=$FILE_NAME"
  info "process:\t$URI_STEP"
  while [[ $STEP_CONTINUE == "1" ]]; do
    step
  done
  ok "all done"
}

# обработка всех файлов в архиве
function processzip {
  info "process zip:\t$URI_STEP"
  zipinfo -1 "$SRC_FILE" | while read -d $'\n' PROCESS_FILENAME; do
    URI_STEP="$URI?type=catalog&mode=$GET_STEP_MODE&filename=$PROCESS_FILENAME"
    info "process file:\t$PROCESS_FILENAME"
    STEP_CONTINUE=1
    while [[ $STEP_CONTINUE == "1" ]]; do
      step
    done
  done
}

# проверка входных параметров, подстановка значений по-умолчанию
function checkenv {

  if [ ! -f "$SRC_FILE" ]; then
    error "File not exists: $SRC_FILE"
    error "Use: Docker ... -v /path/to/upload/file.xml:/src"
    exit 1
  fi

  if [ -z "$SITE" ]; then
    error "Env parameter not set: SITE"
    exit 1
  fi

  if [ -z "$AUTH_LOGIN" ]; then
    error "Env parameter not set: AUTH_LOGIN"
    exit 1
  fi

  if [ -z "$AUTH_PASS" ]; then
    error "Env parameter not set: AUTH_PASS"
    exit 1
  fi

  if [ -z "$CHARSET_IN" ]; then
    CHARSET_IN=utf-8
  fi

  if [ -z "$CHARSET_OUT" ]; then
    CHARSET_OUT=utf-8
  fi

  if [ -z "$GET_STEP_MODE" ] ; then
    GET_STEP_MODE=import
  fi

}

info "Start importing file $FILE_NAME on $SITE"

checkenv

cp "$SRC_FILE" "/var/log/$FILE_NAME"

checkauth
init
upload

if [ -n "$ZIP" ] && [ "$ZIP" -eq "1" ]; then
  processzip
else
  process
fi
