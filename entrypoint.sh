#!/bin/sh
/usr/sbin/postconf maillog_file=/var/log/postfix.txt
python3 -m http.server --directory / &
/usr/sbin/postfix start-fg
