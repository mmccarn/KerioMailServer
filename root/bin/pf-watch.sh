#!/bin/bash
(tcpdump -n -e -t -i pflog0 &) |awk -F"[: .]" '{print $9"."$10"."$11"."$12" > "$19}'
#sed 's/: Flags.*//'
