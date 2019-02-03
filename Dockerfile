FROM alpine

RUN apk add curl && \
    apk add bash && \
    apk add zip

ADD /scripts /scripts
WORKDIR /scripts

ENV PATH="$PATH:$WORKDIR" \
    CHARSET_IN="utf-8" \
    CHARSET_OUT="utf-8" \
    # Уровень "молчания" curl: "показывать только ошибки, скрыть прогресс бар" \
    CURL_VERBOSITY="-sS" \
    # Импорт осуществляется из этого файла, который монтируется с хоста \
    SRC_FILE="/src" \
    # Файл кукисов \
    COOK="/var/log/cookiefile.txt" \
    # "mode" при импорте файлов \
    GET_STEP_MODE="import"

CMD generic
