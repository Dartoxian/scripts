#!/bin/ash

set -x

clear_leds() {
	# Delete all of the led system rules
	while uci -q delete system.@led[0]; do :; done
	uci commit
}
 
enable_led() {
	# Sets the broadband led to flash red on internal traffic, green on internet traffic
	# Disables the main blue LED and permanently illuminates the green LED
	# Flashes blue wifi on radio activity

	echo "Running enable led"
	clear_leds

	name=$(uci add system led)
	uci batch <<EOF set system.$name.name='wifi'
set system.$name.sysfs='bthomehubv5a:blue:wireless'
set system.$name.trigger='phy0tpt'
EOF
	name=$(uci add system led)	
	uci batch <<EOF set system.$name.name='dsl'
set system.$name.default='0'
set system.$name.trigger='netdev'
set system.$name.mode='link tx rx'
set system.$name.dev='eth0.1'
set system.$name.sysfs='bthomehubv5a:red:broadband'
EOF
	name=$(uci add system led)
	uci batch <<EOF set system.$name.trigger='none'
set system.$name.name='opewrt indicator'
set system.$name.default='1'
set system.$name.sysfs='bthomehubv5a:green:power'
EOF
	name=$(uci add system led)
	uci batch <<EOF set system.$name.trigger='none'
set system.$name.sysfs='bthomehubv5a:blue:power'
set system.$name.name='off blue power'
set system.$name.default='0'
EOF
	
	name=$(uci add system led)
	uci batch <<EOF set system.$name.sysfs='bthomehubv5a:green:broadband'
set system.$name.default='0'
set system.$name.trigger='netdev'
set system.$name.mode='tx rx'
set system.$name.name='Direct internet traffic'
set system.$name.dev='eth0.2'
EOF

	uci commit
}

disable_led() {
	echo "Running disable led"
	clear_leds

	# Sets all of the LEDS modified above to be turned off during the night hours.

	name=$(uci add system led)
	uci batch <<EOF set system.$name.name='wifi'
set system.$name.default='0'
set system.$name.sysfs='bthomehubv5a:blue:wireless'
set system.$name.trigger='none'
EOF
	name=$(uci add system led)	
	uci batch <<EOF set system.$name.name='dsl'
set system.$name.default='0'
set system.$name.trigger='none'
set system.$name.sysfs='bthomehubv5a:red:broadband'
EOF
	name=$(uci add system led)
	uci batch <<EOF set system.$name.trigger='none'
set system.$name.name='opewrt indicator'
set system.$name.default='0'
set system.$name.sysfs='bthomehubv5a:green:power'
EOF
	name=$(uci add system led)
	uci batch <<EOF set system.$name.trigger='none'
set system.$name.sysfs='bthomehubv5a:blue:power'
set system.$name.name='off blue power'
set system.$name.default='0'
EOF
	
	name=$(uci add system led)
	uci batch <<EOF set system.$name.sysfs='bthomehubv5a:green:broadband'
set system.$name.default='0'
set system.$name.trigger='none'
set system.$name.name='Direct internet traffic'
EOF

	uci commit
}


forced=$1
currenttime=$(date +%H:%M)
if [ ! -z "$forced" ]; then
	if [ "$forced" == "disable" ]; then
		disable_led
	elif [ "$forced" == "enable" ]; then
		enable_led
	else
		echo "If a 'force' argument is supplied it must be disable or enable"
		exit 1
	fi
else
	if [ "$currenttime" \> "21:00" ] || [ "$currenttime" \< "06:30" ]; then
		disable_led
	else
		enable_led
	fi
fi

/etc/init.d/led restart
