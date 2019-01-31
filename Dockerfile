FROM alpine

RUN apk add curl && \
    apk add bash && \
    apk add zip && \
    mkdir -p /scripts/data && \
    mkdir -p /scripts/log

ADD /scripts /scripts
WORKDIR /scripts

CMD ./import-generic.sh
