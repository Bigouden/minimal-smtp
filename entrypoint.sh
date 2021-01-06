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
python3 -m http.server --directory / > /dev/null 2>&1 &
/usr/sbin/postfix start-fg
