#!/bin/bash
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
UPDATE=FALSE

if [ ! -s /var/run/emerging-ipset-update.fwrev ]; then
  UPDATE=TRUE
elif ! ( cmp /var/run/emerging-ipset-update.fwrev <(curl -s https://rules.emergingthreats.net/fwrules/FWrev) >/dev/null 2>&1 ); then
  UPDATE=TRUE
fi

if [ "$UPDATE" = "TRUE" ]; then
  if curl -s https://rules.emergingthreats.net/fwrules/emerging-Block-IPs.txt -o /tmp/emerging-Block-IPs.txt;
  then
    printf "$(date '+%Y-%m-%d %H:%M:%S')\tSUCCESS\tcurl -s https://rules.emergingthreats.net/fwrules/emerging-Block-IPs.txt -o /tmp/emerging-Block-IPs.txt\n"
    cp /tmp/emerging-Block-IPs.txt /etc/pf-emerging-Block-IPs.txt   \
      && printf "$(date '+%Y-%m-%d %H:%M:%S')\tSUCCESS\tcp /tmp/emerging-Block-IPs.txt /etc/etc/pf-emerging-Block-IPs.txt\n"
    chmod 644 /etc/pf-emerging-Block-IPs.txt && printf "$(date '+%Y-%m-%d %H:%M:%S')\tSUCCESS\tchmod 644 /etc/pf-emerging-Block-IPs.txt\n"
    if pfctl -f /etc/pf.conf 2>/dev/null;
    then
      printf "$(date '+%Y-%m-%d %H:%M:%S')\tSUCCESS\tpfctl -f /etc/pf.conf\n"
    else
      printf "$(date '+%Y-%m-%d %H:%M:%S')\tERROR\tpfctl -f /etc/pf.conf\n"
    fi
    if curl -s https://rules.emergingthreats.net/fwrules/FWrev > /var/run/emerging-ipset-update.fwrev 2>&1; then
      printf "$(date '+%Y-%m-%d %H:%M:%S')\tSUCCESS\t/var/run/emerging-ipset-update.fwrev updated\n"
    else
      printf "$(date '+%Y-%m-%d %H:%M:%S')\tERROR\t/var/run/emerging-ipset-update.fwrev NOT updated\n"
    fi
  else
    printf "$(date '+%Y-%m-%d %H:%M:%S')\tERROR\tcurl -s https://rules.emergingthreats.net/fwrules/emerging-Block-IPs.txt -o /tmp/emerging-Block-IPs.txt\n"
  fi
else
  printf "$(date '+%Y-%m-%d %H:%M:%S')\tNOUPDATE\tFWRev $(cat /var/run/emerging-ipset-update.fwrev) unchanged\n"
fi
