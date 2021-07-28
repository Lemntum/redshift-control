#!/bin/bash

# Set the desired location for the log file.
conf_file="$HOME/.config/redshift_control.conf"

apply_redshift () {
	redshift -PO $temperature -b $brightness
	sed -i "s/^temperature=.*/temperature=$temperature/" $conf_file
	sed -i "s/^brightness=.*/brightness=$brightness/" $conf_file
}

min () {
	if [ $# -eq 2 ]; then
		[ $(echo "$1<$2" | bc) -eq 1 ] && echo $1 || echo $2
	fi
}

max () {
	if [ $# -eq 2 ]; then
		[ $(echo "$1>$2" | bc) -eq 1 ] && echo $1 || echo $2
	fi
}

set_temperature () {
	if [ $# -eq 1 ]; then
		max $(min $1 $max_temp) $min_temp
	fi
}

set_brightness () {
	if [ $# -eq 1 ]; then
		max $(min $1 $max_brightness) $min_brightness
	fi
}

increase_temperature () {
	set_temperature $(echo "$temperature + $step_temp" | bc)
}

decrease_temperature () {
	set_temperature $(echo "$temperature - $step_temp" | bc)
}

increase_brightness () {
	set_brightness $(echo "$brightness + $step_brightness" | bc)
}

decrease_brightness () {
	set_brightness $(echo "$brightness - $step_brightness" | bc)
}

reset_levels () {
	redshift -x
	sed -i "s/^temperature=.*/temperature=6500/" $conf_file
	sed -i "s/^brightness=.*/brightness=1/" $conf_file

	exit
}

if [ ! -f "$conf_file" ]; then
	cat > $conf_file << CONF
### Do not manually change these two lines ###
temperature=6500
brightness=1

### SETTINGS ###
# Set temperature values. 6500 is default. Lower is more red.
step_temp=500
max_temp=6500
min_temp=1500

# Set brightness values. Brightness cannot go above 1.
step_brightness=0.1
max_brightness=1
min_brightness=0.5
CONF
fi

. $conf_file

for arg in "$@"; do
	case "$arg" in
		"increase") temperature=$(increase_temperature); brightness=$(set_brightness $brightness) ;;
		"decrease") temperature=$(decrease_temperature); brightness=$(set_brightness $brightness) ;;
		"brighter") brightness=$(increase_brightness); temperature=$(set_temperature $temperature) ;;
		"darker"  ) brightness=$(decrease_brightness); temperature=$(set_temperature $temperature) ;;
		"max"     ) temperature=$max_temp; brightness=$max_brightness ;;
		"min"     ) temperature=$min_temp; brightness=$min_brightness ;;
		"set"     ) : ;;  # pass
		"reset"   ) reset_levels ;;
		*         ) echo "$arg is not a valid command." ; exit ;;
	esac
	
	apply_redshift
done
