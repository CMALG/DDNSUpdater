# DDNSUpdater

Since i ran into issues with the Cisco build in ddns updater i created this script to suite my needs.

### You need to update some setting in the DDNSUpdater.tcl 
```
TCL DDNS Update Script for Cisco ISR 4K Router
Tested with 

Embedded Event Manager Version 4.00
Component Versions:
  eem: (dev10)1.1.5
 
This script works for IPv4 and IPv6
Enable the IP Protocol Version you want to use
```
### Router config
```
Place the script onto device flash and run:
 event manager directory user policy flash:/
 event manager policy DDNSUpdater.tcl
```

### Use one of the following events

```
This event lets this scipt run every 600 seconds
 ::cisco::eem::event_register_timer watchdog time 600

This event reads syslog and runs when a pattern is detected 
 ::cisco::eem::event_register_syslog pattern {ip sla 1 reachability Up->Down}

  
You can call this script directly from an eem applet, therefore do not register the policy
call it from any eem applet one simple example run the updater every day @5am
add this to your config
	
	event manager applet DDNSUpdater
 	event timer cron cron-entry 0 5 * * *
 	action 001 cli command "enable"
 	action 002 cli command "tclsh flash:DDNSUpdater.tcl"
	action 003 cli command "end"
 	
  replace the event in the script with
  ::cisco::eem::event_register_none maxrun 30 queue_priority low nice 0
  
```
### Variables you need to change
```
# Name of the Interface where the IP should be taken from (Dialer 1, FastEthernet0/0 ...)
set interface "Dialer1"
# Enable IPv4 Update with "1" disable with "0"
set ipv4update "1"
# Enable IPv6 Update with "1" disable with "0"
set ipv6update "0"

```

### If you want to update your ip on more than one service just copy&paste the ipv4 or ipv6 block
