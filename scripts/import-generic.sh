#!/bin/bash

# Кастомный импорт CSV файла

FILE="data/import-file"
COOK="data/cookiefile.txt"
URI="$SITE/bitrix/admin/1c_exchange.php"

URI_CHECKAUTH="$URI?type=catalog&mode=checkauth"
URI_INIT="$URI?type=catalog&mode=init"
URI_UPLOAD="$URI?type=catalog&mode=file&filename=$FILE_NAME"
URI_STEP="$URI?type=catalog&mode=import&filename=$FILE_NAME"

STEP_CONTINUE=1
CURL_VERBOSITY="-sS"


source lib/colors.sh
# assert, info, ok, warning, error:
source lib/functions.sh

function checkauth {
  info "checkauth:\t$URI_CHECKAUTH"
  curl $CURL_VERBOSITY -c $COOK $URI_CHECKAUTH --user "$AUTH_LOGIN":"$AUTH_PASS" --trace-ascii data/curl-debug.txt > data/01-checkauth.txt
  assert "$?" "0" "Login fails"
}

function init {
  info "init:\t\t$URI_INIT"
  curl $CURL_VERBOSITY -c $COOK -b $COOK $URI_INIT --user "$AUTH_LOGIN":"$AUTH_PASS" --trace-ascii data/curl-debug.txt > data/02-init.txt
  assert "$?" "0" "Init fails"
}

function upload {
  info "upload file:\t$URI_UPLOAD"
  curl $CURL_VERBOSITY -c $COOK -b $COOK -X POST --data-binary @- $URI_UPLOAD --user "$AUTH_LOGIN":"$AUTH_PASS" -H "Content-Type: application/octet-stream" -H "Expect:" --trace-ascii data/curl-debug.txt < $FILE > data/03-file.txt
  assert "$?" "0" "File upload fails"
}

function step {
  curl $CURL_VERBOSITY -c $COOK -b $COOK $URI_STEP --user "$AUTH_LOGIN":"$AUTH_PASS" --trace-ascii data/curl-debug.txt > data/step.txt
  assert "$?" "0" "Progress file fails (curl error)"

  echo
  iconv -f $CHARSET_IN -t $CHARSET_OUT data/step.txt
  echo

  if grep -q failure data/step.txt ; then
    error "Progress file fails (error in response)"
    exit 1
  fi

  if grep -q progress data/step.txt ; then
    STEP_CONTINUE=1
  else
    STEP_CONTINUE=0
  fi
}

function run {
  info "run steps:\t$URI_STEP"
  while [[ $STEP_CONTINUE == "1" ]]; do
    step
  done
  ok "all done"
}

info "Start importing file $FILE_NAME on $SITE"
checkauth
init
upload
run

# /bin/bash
