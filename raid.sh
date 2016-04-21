#!/bin/bash
# A simple note of using mdadm
RAID="/dev/md0"
DEFAULT_DISK=""

BLUE='\e[94m'
CYAN='\e[96m'
RED='\e[31m'
END='\e[0m'

function parted(){
	(echo n; echo; echo; echo '+100M'; echo; \
	 echo n; echo; echo; echo '+100M'; echo; \
	 echo n; echo; echo; echo '+100M'; echo; \
	 echo n; echo; echo; echo '+100M'; echo; \
	 echo p; echo w; echo Y; echo q;) | gdisk ${DISK} &> /dev/null
	gdisk -l ${DISK}
}

function erase(){
	(echo d; echo 1; \
	 echo d; echo 2; \
	 echo d; echo 3; \
	 echo d; echo 4; \
	 echo p; echo w; echo Y; echo q;) | gdisk ${DISK} &> /dev/null
	gdisk -l ${DISK}
}

function raid5(){
	msg "Create ${RAID} as a new RAID level 5 array from ${DISK}1, ${DISK}2, ${DISK}3 and ${DISK}4"
	cmd "mdadm --create ${RAID} --auto=yes --level=5 --raid-devices=3 --spare-devices=1 ${DISK}{1,2,3,4}"
	detail
	alert "Use the following command to see the rebuild status"
	alert "${0} detail ${DISK}"
}

function unraid5(){
	cmd "mdadm --stop ${RAID}"
	cmd "mdadm --zero-superblock ${DISK}{1,2,3,4}"
}

function fail(){
	msg "Mark the ${DISK}1 device as faulty"
	cmd "mdadm ${RAID} --fail ${DISK}1"
	detail
	alert "Use the following command to see the rebuild status"
	alert "${0} detail ${DISK}"
}

function repair(){
	msg "Remove it from the RAID device ${RAID}, and add the device back to the array"
	cmd "mdadm ${RAID} --remove ${DISK}1"
	cmd "mdadm ${RAID} --add ${DISK}1"
	detail
}

function detail(){
	cmd "mdadm --detail ${RAID}"
}

function msg(){
	echo -e ${BLUE}$@${END}
}

function alert(){
	echo -e ${RED}$@${END}
}

function cmd(){
	echo -e ${CYAN}$@${END}
	eval $@
}

function help(){
	echo "Usage ${0} {command} {device}"
	echo " - command: 
	+--------+     +-------+       +------+
	| parted +---> | raid5 +-----> | fail +-----+
	+--------+     +-------+       +------+     |
						    |
	+-------+      +---------+     +--------+   |
	| erase | <----+ unraid5 | <---+ repair | <-+
	+-------+      +---------+     +--------+ "
	echo " - device: /dev/sd?"
	exit -1
}

if [ $# -gt "2" ]; then
	help
fi

TYPE=$1
DISK=$2
[ "x${DISK}" == "x" ] && [ "x${DEFAULT_DISK}" == "x" ] && help
[ "x${DISK}" == "x" ] && DISK=${DEFAULT_DISK}

case ${TYPE} in
"parted")
	parted
	;;
"erase")
	erase
	;;
"raid5")
	raid5
	;;
"unraid5")
	unraid5
	;;
"fail")
	fail
	;;
"repair")
	repair
	;;
"detail")
	detail
	;;
*)
	help
	;;
esac
