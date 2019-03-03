#!/bin/bash
#
# script to monitor 'security.log' (failed login attempts) and block any IPs
# that do not also appear in 'audit.log' (successful login attempts)
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

LOGDIR=/Volumes/MailStore/logs
BADLOG=${LOGDIR}/security.log
GOODLOG=${LOGDIR}/audit.log
WHITEIPS="192.168.1|10.0.150|62.254.94.50|145.131.253.200"
BLOCKLIST=/etc/pf.blocked.ip.conf
BLOCKTIME=$(( 60 * 60 * 72 ))
MSG=""

# make all comparisons ignore case
shopt -s nocasematch

# update BLOCKLIST before
pfctl -t blockips -T show 2>/dev/null  |sed 's/ //g' > ${BLOCKLIST}

# get good IPs from audit.log
MSG+="$(date '+%Y-%m-%d %H:%M:%S')\tGetting good IPs from ${GOODLOG}"
GOODIPS=$(nice egrep -v ${WHITEIPS} /Volumes/MailStore/logs/audit.log |grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" |sort -u)
MSG+="\t$(echo $GOODIPS |wc -w) IPs found\n"

# get bad IPs from security.log
MSG+="$(date '+%Y-%m-%d %H:%M:%S')\tScanning ${BADLOG} for IMAP, POP3, and SMTP authentication errors"
SMTPERRORS=$(egrep "IMAP|POP3|SMTP" ${BADLOG} | egrep -v ${WHITEIPS} |grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" |sort -u)
MSG+="\t$(echo $SMTPERRORS |wc -w) IPs found\n"

if [[ $1 == *"v"* ]]; then
  printf "$MSG"
fi
MSG=""

for ip in $SMTPERRORS;
do
  MSG+="$(date '+%Y-%m-%d %H:%M:%S')\t$ip"

  if [[ $GOODIPS == *"$ip"* ]]; then
    MSG+="\tfound in $GOODLOG"
      if grep $ip $BLOCKLIST >/dev/null 2>&1; then
        pfctl 2>/dev/null -t blockips -T delete $ip
        MSG+="\tremoved from pf list blockips"
      fi
  else
    MSG+="\tnot found in $GOODLOG"
    if grep $ip ${BLOCKLIST} >/dev/null 2>&1; then
      MSG+="\tfound in $BLOCKLIST"
    else
      if pfctl >/dev/null 2>&1 -t blockips -T add $ip; then
        MSG+="\tadded to pf list blockips"
      else
        MSG+="\tERROR adding ip to pf list blockips"
      fi
    fi
  fi
  MSG+="\n"
  if [[ ( $MSG == *"adding"* ) || ( $MSG == *"removed"* ) || ( $MSG == *"ERROR"* ) || ( $1 == *"vv"* ) ]]; then
    printf "$MSG"
  fi
done

# update BLOCKLIST
pfctl -t blockips -T show 2>/dev/null  |sed 's/ //g' > ${BLOCKLIST}

# expire unused entries in badips
EXPIRES=$(pfctl 2>&1 -t blockips -T expire $BLOCKTIME |grep -i expired)
if [[ ( ! $EXPIRES == *"0/0"* ) || ( $1 == *"v"* ) ]]; then
  printf "$(date '+%Y-%m-%d %H:%M:%S')\tpfctl -t blockips -T expire $BLOCKTIME\t$EXPIRES\n"
fi

# update BLOCKLIST
pfctl -t blockips -T show 2>/dev/null  |sed 's/ //g' > ${BLOCKLIST}
