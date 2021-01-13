FROM alpine:3.12
LABEL maintainer="Thomas GUIRRIEC <thomas@guirriec.fr>"
ARG BUSYBOX_URL="https://busybox.net/downloads"
WORKDIR /tmp
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]
# Compile index.cgi to add directory listing for busybox httpd applet
RUN apk add --no-cache --update --virtual \
      build-dependencies \
        gcc \
        grep \
        libc-dev \
        wget \
    # Retrieve busybox version
    && BUSYBOX_VERSION=busybox-$(busybox | grep -oP "v\K[0-9]+\.[0-9]+\.[0-9]+") \
    # Download busybox source archive
    && wget -O "$BUSYBOX_VERSION.tar.bz2" "$BUSYBOX_URL/$BUSYBOX_VERSION.tar.bz2" \
    # Decompress & extract busybox source archive
    && tar -xf "$BUSYBOX_VERSION.tar.bz2" \
    # Create /cgi-bin directory
    && mkdir /cgi-bin/ \
    # Compile index.cgi
    && gcc -o /cgi-bin/index.cgi "$BUSYBOX_VERSION/networking/httpd_indexcgi.c" \
           -static \
           -static-libgcc \
           -D_LARGEFILE_SOURCE \
           -D_LARGEFILE64_SOURCE \
           -D_FILE_OFFSET_BITS=64 \
           -Wall \
           -Os \
           -fno-builtin \
           -finline-limit=0 \
           -fomit-frame-pointer \
           -ffunction-sections \
           -fdata-sections \
           -fno-guess-branch-probability \
           -funsigned-char \
           -falign-functions=1 \
           -falign-jumps=1 \
           -falign-labels=1 \
           -falign-loops=1 \
    # Postfix Installation
    && apk add --update --no-cache \
        busybox-extras \
        ca-certificates \
        openssl \
        postfix-pcre \
        postfix-ldap \
        postfix \
    # Cleanup
    && apk del build-dependencies \
    && rm -rf \
         /etc/postfix/* \
         /tmp/* \ 
         /root/.cache/* \
         /var/cache/*
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
