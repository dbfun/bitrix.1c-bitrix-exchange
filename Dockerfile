FROM alpine

RUN apk add curl && \
    apk add bash && \
    apk add zip

ADD /scripts /scripts
WORKDIR /scripts

CMD ./import-generic.sh
