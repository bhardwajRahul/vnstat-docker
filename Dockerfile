FROM alpine:latest AS base

LABEL org.opencontainers.image.authors="Teemu Toivola"
LABEL org.opencontainers.image.url="https://humdi.net/vnstat/"
LABEL org.opencontainers.image.source="https://github.com/vergoh/vnstat-docker"
LABEL org.opencontainers.image.title="vnStat"
LABEL org.opencontainers.image.description="vnStat (https://humdi.net/vnstat/) in a container with image output via http"

ENV HTTP_PORT=8685
ENV HTTP_BIND=*
ENV HTTP_LOG=/dev/stdout
ENV LARGE_FONTS=0
ENV CACHE_TIME=1
ENV DARK_MODE=0
ENV PAGE_REFRESH=0
ENV INDEX_IMAGES_PER_ROW=1
ENV INDEX_IMAGE_OUTPUT=hs
ENV RUN_VNSTATD=1

COPY favicon.ico /var/www/localhost/htdocs/favicon.ico
COPY start.sh /

RUN true \
    && set -ex \
    && apk add --no-cache \
        tzdata \
        gd \
        perl \
        lighttpd \
        sqlite-libs


FROM alpine:latest AS builder

RUN true \
    && set -ex \
    && apk add --no-cache \
        gcc \
        make \
        musl-dev \
        linux-headers \
        gd-dev \
        sqlite-dev \
    && wget https://humdi.net/vnstat/vnstat-latest.tar.gz \
    && tar zxvf vnstat-latest.tar.gz \
    && cd vnstat-*/ \
    && ./configure --prefix=/usr --sysconfdir=/etc \
    && make \
    && make install


FROM base AS runtime

COPY --from=builder /usr/bin/vnstat /usr/bin/vnstat
COPY --from=builder /usr/bin/vnstati /usr/bin/vnstati
COPY --from=builder /usr/sbin/vnstatd /usr/sbin/vnstatd
COPY --from=builder /etc/vnstat.conf /etc/vnstat.conf
COPY --from=builder vnstat-*/examples/vnstat.cgi /var/www/localhost/htdocs/index.cgi
COPY --from=builder vnstat-*/examples/vnstat-json.cgi /var/www/localhost/htdocs/json.cgi
COPY --from=builder vnstat-*/examples/vnstat-metrics.cgi /var/www/localhost/htdocs/metrics.cgi

RUN true \
    && set -ex \
    && addgroup -S vnstat \
    && adduser -S -h /var/lib/vnstat -s /sbin/nologin -g vnStat -D -H -G vnstat vnstat

VOLUME /var/lib/vnstat
EXPOSE ${HTTP_PORT}

CMD [ "/start.sh" ]
