#!/bin/sh

################
# Classic Mode #
################

[ -z "${CI}" ] && /usr/sbin/postfix start-fg

###############
# Gitlab Mode #
###############

# Configure Postfix Log (Classic Directory)
/usr/sbin/postconf maillog_file=/var/log/mail.log
# Launch HTTP Server (Background)
httpd -h / -p 8000
/usr/sbin/postfix start-fg
