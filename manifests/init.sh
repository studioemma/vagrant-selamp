#!/bin/bash

function age() {
   local filename=$1
   local changed=`stat -c %Y "$filename"`
   local now=`date +%s`
   local elapsed

   let elapsed=now-changed
   echo $elapsed
}

if [ ! -e /var/cache/vagrant-apt-update ]; then
	apt-get update
	echo "1" > /var/cache/vagrant-apt-update
else
	age=$(age /var/cache/vagrant-apt-update)
	if ((age > 604800)); then # wait seven days
		apt-get update
		echo "1" > /var/cache/vagrant-apt-update
	fi
fi

if [ "$(date +%Z)" == "UTC" ]; then
	echo "Europe/Brussels" > /etc/timezone
	dpkg-reconfigure --frontend noninteractive tzdata 2>&1
fi
