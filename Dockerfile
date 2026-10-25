FROM alpine:latest
RUN apk add --no-cache bash curl
COPY attack.sh /usr/local/bin/attack.sh
RUN chmod +x /usr/local/bin/attack.sh
CMD ["/usr/local/bin/attack.sh"]
