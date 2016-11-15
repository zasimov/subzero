FROM alpine:latest

RUN apk update
RUN apk add libffi
RUN apk add gmp
RUN apk add libc6-compat

RUN ln -s /lib /lib64

ADD subzero /usr/local/bin

ADD entrypoint.sh /

RUN chmod +x /entrypoint.sh

ENV SCROLL scroll.txt
ENV SUBZERO_PORT 5002

ENTRYPOINT ["/entrypoint.sh"]
