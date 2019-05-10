# TCL DDNS Update Script for Cisco ISR 4K Router
# Tested with 
#
#	Embedded Event Manager Version 4.00
#	Component Versions:
#	eem: (dev10)1.1.5
# 
#  This script works for IPv4 and IPv6
#  Enable the IP Protocol Version you want to use
#	
# Place the script onto device flash and run:
# event manager directory user policy flash:/
# event manager policy DDNSUpdater.tcl
#
# Use one of the following events
#  
#	This event lets this scipt run every 600 seconds
# ::cisco::eem::event_register_timer watchdog time 600
#
# 	This event reads syslog and runs when a pattern is detected 
# ::cisco::eem::event_register_syslog pattern {ip sla 1 reachability Up->Down}
#
#  
#	You can call this script directly from an eem applet, therefore do not register the policy
# 	call it from any eem applet one simple example run the updater every day @5am
# 	add this to your config
#	
#	event manager applet DDNSUpdater
# 	event timer cron cron-entry 0 5 * * *
# 	action 001 cli command "enable"
# 	action 002 cli command "tclsh flash:DDNSUpdater.tcl"
#	action 003 cli command "end"
# 	
#   ::cisco::eem::event_register_none maxrun 30 queue_priority low nice 0
# 



namespace import ::cisco::eem::*
namespace import ::cisco::lib::*


# remove this event if you are using one of the others
::cisco::eem::event_register_timer watchdog time 600

# Variables
# Name of the Interface where the IP should be taken from (Dialer 1, FastEthernet0/0 ...)
set interface "Dialer1"
# Enable IPv4 Update with "1" disable with "0"
set ipv4update "1"
# Enable IPv6 Update with "1" disable with "0"
set ipv6update "0"


action_syslog msg "Fetching WAN address"

#open cli session
if [catch {cli_open} result] {
	error $result $errorInfo
	} else {
	array set cli $result
	 }

# send Enable
if [catch {cli_exec $cli(fd) "enable"} result] {
	error $result $errorInfo
	}




#IPv4 Block	
if {$ipv4update == 1} {
	
# get sh run ip int br | section $interface output
if [catch {cli_exec $cli(fd) "sh ip int br | section $interface"} result] {
	error $result $errorInfo
	} else {
	set output $result
	}
	
#get the IPv4 ip with regex
regexp {(?:\d+\.){3}\d+} $output wanaddr

action_syslog msg "Updating DDNS with IPv4 WAN: ($wanaddr) ($interface)"

action_syslog msg "Updating record for DDNS ..."

# Update URL you have to figure out yourself depends on the DDNS provider use place $wanaddr where the IP address in the url should be
set updateurl "YourupdateURL.de?ip=$wanaddr"
if {[catch {http::geturl $updateurl -queryblocksize 50 -type "text/plain" } token]} {
        action_syslog msg "Update failed. URL not reachable. Try pinging hostname to check reachability"
 } else {
        action_syslog msg "Updateserver response: [http::data $token]"
 }
	 
} 
#End IPv4 Block



#IPv6 Block
if  {$ipv6update == 1} {
# get show ipv6 interface $interface
if [catch {cli_exec $cli(fd) "show ipv6 interface $interface"} result] {
	error $result $errorInfo
	} else {
	set output $result
	}
#Filer the Global unicast section
regexp {Global unicast.*subnet{1}} $output ipv6int
#get the IPv6 ip with regex
regexp {(([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{1,4})} $ipv6int wanaddr	

action_syslog msg "Updating DDNS with IPv6 WAN: ($interface)"

action_syslog msg "Updating record for DDNS ..."

# Update URL you have to figure out yourself depends on the DDNS provider use place $wanaddr where the IP address in the url should be
set updateurl "YourupdateURL.de?ip=$wanaddr"

if {[catch {http::geturl $updateurl -queryblocksize 50 -type "text/plain" } token]} {
        action_syslog msg "Update failed. URL not reachable. Try pinging hostname to check reachability"
 } else {
        action_syslog msg "Server message: [http::data $token]"
 } 	 
	 
} 

#End IPv6 Block



#free vty line	 

if [catch {cli_close $cli(fd) $cli(tty_id) } result ] {
		error $result $errorinfo 
	}
	 
exit 0