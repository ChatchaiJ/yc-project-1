#!/bin/sh

for disk in /dev/sd?; do
	DISK=$(echo $disk | cut -f3 -d/)
	SIZE=$(cat /sys/block/${DISK}/size)
	[ "${SIZE}" != 0 ] && echo "${disk} ${SIZE}"
done | sort -n -k2 | head -1 | cut -f1 -d' '
