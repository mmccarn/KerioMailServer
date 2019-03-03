# Emerging Threats IP Block on OS X 10.6 
Darwin Kernel Version 14.5.0

## Overview
  * [enable OS X Application Firewall in system preferences](#enable-the-os-x-application-firewall)
  * [update /etc/pf.conf to recognize and use the blocklist](#update-etcpfconf-to-recognize-and-use-the-blocklist)
  * [Run /root/bin/emerging-threats-update.sh to download the latest IP Blocklist and load the updated pf.conf](#run-rootbinemerging-threats-updatesh)
  * [Schdule daily update checks](#schedule-daily-update-checks)
  * [Monitor performance](#monitor-performance)

## Enable the OS X Application Firewall
  https://support.apple.com/en-us/HT201642
  
## update /etc/pf.conf to recognize and use the blocklist
Add these lines to the end of /etc/pf.conf
```
table <emerging_threats> persist file "/etc/pf-emerging-Block-IPs.txt"
block quick log from <emerging_threats> to any
```

Test your changes
```bash
pfctl -n -f /etc/pf.conf
```

## Run /root/bin/emerging-threats-update.sh
* Create or update [/root/.bash_profile](https://github.com/mmccarn/KerioMailServer/blob/master/root/.bash_profile) to add ~/bin to your path
* Download [emerging-threats-update.sh](https://github.com/mmccarn/KerioMailServer/blob/master/root/bin/emerging-threats-update.sh) to /root/bin
* Make the downloaded file executable
```bash
chmod +x /root/bin/emerging-threats-update.sh
```
* Run the command
```bash
/root/bin/emerging-threats-update.sh
```
* Verify that the "emerging_threats" table exists (Note that my system shows "No ALTQ support" despite having enabled the application fireall in System Preferences)
```
## pfctl -s Tables
No ALTQ support in kernel
ALTQ related functions disabled
blockips
emerging_threats
localips
```
## Verify that the table has data
```bash
# pfctl -t emerging_threats -T show |head -5
No ALTQ support in kernel
ALTQ related functions disabled
   1.10.16.0/20
   1.32.128.0/18
   2.50.28.190
   2.50.144.32
   5.8.37.0/24
 
# pfctl -t emerging_threats -T show |wc -l
No ALTQ support in kernel
ALTQ related functions disabled
    1117
```
## Other Useful tidbits
Search online for [pfctl cheath sheet](https://gist.github.com/tracphil/4353170) to see more options
<pre># cat /var/run/emerging-ipset-update.fwrev
5205</pre>

<pre># pfctl -vvs Tables
No ALTQ support in kernel
ALTQ related functions disabled
-pa-r-  blockips
        Addresses:   137
        Cleared:     Thu Feb 28 18:44:41 2019
        References:  [ Anchors: 0                  Rules: 7                  ]
        Evaluations: [ NoMatch: 24753765           Match: 362215             ]
        In/Block:    [ Packets: 96889              Bytes: 5836259            ]
        In/Pass:     [ Packets: 0                  Bytes: 0                  ]
        In/XPass:    [ Packets: 0                  Bytes: 0                  ]
        Out/Block:   [ Packets: 0                  Bytes: 0                  ]
        Out/Pass:    [ Packets: 0                  Bytes: 0                  ]
        Out/XPass:   [ Packets: 0                  Bytes: 0                  ]
-pa-r-  emerging_threats
        Addresses:   1117
        Cleared:     Fri Mar  1 08:12:58 2019
        References:  [ Anchors: 0                  Rules: 1                  ]
        Evaluations: [ NoMatch: 22300957           Match: 36                 ]<u><b>
        In/Block:    [ Packets: 36                 Bytes: 1720               ]</b></u>
        In/Pass:     [ Packets: 0                  Bytes: 0                  ]
        In/XPass:    [ Packets: 0                  Bytes: 0                  ]
        Out/Block:   [ Packets: 0                  Bytes: 0                  ]
        Out/Pass:    [ Packets: 0                  Bytes: 0                  ]
        Out/XPass:   [ Packets: 0                  Bytes: 0                  ]
--a-r-  localips
        Addresses:   1
        Cleared:     Fri Mar  1 15:46:42 2019
        References:  [ Anchors: 0                  Rules: 1                  ]
        Evaluations: [ NoMatch: 4525297            Match: 11511364           ]
        In/Block:    [ Packets: 0                  Bytes: 0                  ]
        In/Pass:     [ Packets: 0                  Bytes: 0                  ]
        In/XPass:    [ Packets: 0                  Bytes: 0                  ]
        Out/Block:   [ Packets: 0                  Bytes: 0                  ]
        Out/Pass:    [ Packets: 0                  Bytes: 0                  ]
        Out/XPass:   [ Packets: 0                  Bytes: 0                  ]
</pre>

## Schedule daily update checks
Add this line to the crontab for root using ```crontab -e``` to schedule updates at 2:04am daily.  ([crontab guru](https://crontab.guru/#4_2_*_*_*))
```
    4 2 * * * /Users/kerioadmin/scripts/emerging-threats-update.sh >> /var/log/aicr-pf.log 2>&1
```
## Monitor performance
### Viewing firewall logs
Packet filter does not log to any file. It logs to a network interface named pflog0.  To watch the firewall activity, you need to create this special interface, then use tcpdump to view the output
```bash
ifconfig create pflog0
tcpdump -n -e -t -i pflog0
ifconfig delete pflog0
```

[pfwatch.sh](https://github.com/mmccarn/KerioMailServer/blob/master/root/bin/pf-watch.sh) is a small script that can be used to extract the remote IP and local PORT from pflog0

### Viewing firewall details and statistics

Already covered -- show all stats for tables
```bash
pfctl -vvs Tables
```
