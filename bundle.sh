#!/bin/bash

#
# Бандл для загрузки на рабочий сайт
#

cd "$(dirname "$0")"

function help {
  local bold=$(tput bold)
  local normal=$(tput sgr0)
  echo -e "${bold}Описание${normal}\n"
  echo -e "\tБандл для загрузки на рабочий сайт \n"
  echo -e "${bold}Syntax:${normal}\n\t./bundle.sh <args>\n"
  echo -e "${bold}Параметры${normal}\n"
  echo -e "\t${bold}-c${normal}\n\t\tвариант обмена\n"
  echo -e "\t${bold}-s${normal}\n\t\tисходный файл (опционально)\n"
  echo -e "\t${bold}-f${normal}\n\t\tимя файла (опционально, будет передан как GET параметр)\n"
  echo -e "\t${bold}-d${normal}\n\t\tDNS (опционально)\n"
  echo -e "\t${bold}-e${normal}\n\t\t.env-файл (опционально, default: .env)\n"
}
function getOptions {
  getDefauls
  if [[ ! -z "$SRC_FILE" ]]; then
    SRC_FILE=`realpath "$SRC_FILE"`
  fi
}

function getDefauls {
  if [[ -z "$FILE_NAME" ]] && [[ ! -z "$_FILE_NAME" ]]; then
    FILE_NAME="$_FILE_NAME"
  fi
  if [[ -z "$SRC_FILE" ]] && [[ ! -z "$_SRC_FILE" ]]; then
    SRC_FILE="$_SRC_FILE"
  fi
  if [[ -z "$ENV_FILE_STRING" ]] ; then
    ENV_FILE_STRING="--env-file .env"
  fi
}

while getopts "hc:s:f:d:e:" arg; do
  case $arg in
    h)
      help
      exit
      ;;
    c)
      CASE="$OPTARG"
      ;;
    s)
      SRC_FILE="$OPTARG"
      ;;
    f)
      FILE_NAME="$OPTARG"
      ;;
    d)
      DNS_STRING="--dns=$OPTARG"
      ;;
    e)
      ENV_FILE_STRING="--env-file $OPTARG"
  esac
done

if [[ -z "$1" ]]; then
  help
  exit
fi

# import.xml - обмен продукцией каталога
if [ "$CASE" == "import.xml" ]; then
  getOptions
  docker  run -it --rm \
          -e FILE_NAME=import.xml \
          $ENV_FILE_STRING \
          $DNS_STRING \
          -v $(pwd)/log/:/var/log/ \
          -v $(pwd)/data/import.xml:/src \
          required/1c-bitrix-exchange:latest
fi

# offers.xml - обмен ценами
if [ "$CASE" == "offers.xml" ]; then
  getOptions
  docker  run -it --rm \
          -e FILE_NAME=offers.xml \
          $ENV_FILE_STRING \
          $DNS_STRING \
          -v $(pwd)/log/:/var/log/ \
          -v $(pwd)/data/offers.xml:/src \
          required/1c-bitrix-exchange:latest
fi

# orders.xml - получение заказов с сайта
if [ "$CASE" == "orders.xml" ]; then
  getOptions
  docker  run -it --rm \
          $ENV_FILE_STRING \
          $DNS_STRING \
          -v $(pwd)/log/:/var/log/ \
          required/1c-bitrix-exchange:latest \
          getorders
fi

# custom.reports - отчеты (custom)
if [ "$CASE" == "custom.reports" ]; then
  _FILE_NAME=1c-2018.07.26-151049-11063
  _SRC_FILE=$(pwd)/data/1c-2018.07.26-151049-11063
  getOptions
  docker  run -it --rm \
          -e FILE_NAME="$FILE_NAME" \
          -e ZIP=1 \
          -e GET_STEP_MODE=report \
          $ENV_FILE_STRING \
          $DNS_STRING \
          -v $(pwd)/log/:/var/log/ \
          -v "$SRC_FILE":/src \
          required/1c-bitrix-exchange:latest
fi

# custom.rezerv - резерв в пути (custom)
if [ "$CASE" == "custom.rezerv" ]; then
  _FILE_NAME=rezerv.zip
  _SRC_FILE=$(pwd)/data/rezerv.zip
  getOptions
  docker  run -it --rm \
          -e FILE_NAME="$FILE_NAME" \
          -e ZIP=1 \
          -e GET_STEP_MODE=rezerv \
          $ENV_FILE_STRING \
          $DNS_STRING \
          -v $(pwd)/log/:/var/log/ \
          -v "$SRC_FILE":/src \
          required/1c-bitrix-exchange:latest
fi


# custom.csv - обмен CSV (custom)
if [ "$CASE" == "custom.csv" ]; then
  _FILE_NAME=stock.csv
  _SRC_FILE=$(pwd)/data/stock.csv
  getOptions
  docker  run -it --rm \
          -e FILE_NAME="$FILE_NAME" \
          $ENV_FILE_STRING \
          $DNS_STRING \
          -v $(pwd)/log/:/var/log/ \
          -v "$SRC_FILE":/src \
          required/1c-bitrix-exchange:latest
fi

# custom.PlanPrih.json - план прихода продукции (custom)
if [ "$CASE" == "custom.PlanPrih.json" ]; then
  _FILE_NAME=PlanPrih.json
  _SRC_FILE=$(pwd)/data/PlanPrih.json
  getOptions
  docker  run -it --rm \
          -e FILE_NAME="$FILE_NAME" \
          $ENV_FILE_STRING \
          $DNS_STRING \
          -v $(pwd)/log/:/var/log/ \
          -v "$SRC_FILE":/src \
          required/1c-bitrix-exchange:latest
fi


# custom.ws.orders - обновление заказов через веб-сервис (custom)
if [ "$CASE" == "custom.ws.orders" ]; then
  _SRC_FILE=$(pwd)/data/orders.json
  getOptions
  docker  run -it --rm \
          -e URI="/lk/ws/orders/?test=1" \
          $ENV_FILE_STRING \
          $DNS_STRING \
          -v $(pwd)/log/:/var/log/ \
          -v "$SRC_FILE":/src \
          required/1c-bitrix-exchange:latest \
          post
fi
