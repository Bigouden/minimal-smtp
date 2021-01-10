FROM alpine:3.12
LABEL maintainer="Thomas GUIRRIEC <thomas@guirriec.fr>"
RUN apk add --update --no-cache \
      ca-certificates \
      openssl \
      postfix \
      python3 \
    && rm -rf \
         /etc/postfix/* \
         /tmp/* \ 
         /root/.cache/*
COPY etc /etc
COPY entrypoint.sh /
COPY postfix-config-check /usr/local/bin/
RUN postfix set-permissions || true \
    && newaliases \
    && mkdir /etc/postfix/ssl \
    && chmod -R 644 /etc/postfix/ \
    && openssl req \
         -batch \
         -new \
         -newkey rsa:2048 \
         -days 365 \
         -nodes \
         -x509 \
         -keyout /etc/postfix/ssl/privkey.pem \
         -out /etc/postfix/ssl/cert.pem \
         -subj '/C=FR/O=TEST/OU=SMTP/CN=minimal.smtp' \
    && cp /etc/postfix/ssl/cert.pem /etc/postfix/ssl/fullchain.pem \
    && cp /etc/postfix/ssl/fullchain.pem /etc/ssl/certs/ \
    && update-ca-certificates \
    && chmod +x /entrypoint.sh \
    && chmod +x /usr/local/bin/postfix-config-check
WORKDIR /etc/postfix/
EXPOSE 25/tcp
VOLUME /var/spool/postfix
HEALTHCHECK CMD /usr/sbin/postfix status || exit 1
ENTRYPOINT ["/entrypoint.sh"]
