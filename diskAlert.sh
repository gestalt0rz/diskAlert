#!/bin/bash

# path of JSON file
JSON="/data/diskAlert/disk.json"

# parse mail addresses from JSON file
ADMIN=$(grep -o '"mail":"[^"]*' $JSON |grep -o '[^"]*$' | tr '\n' ',' | sed 's/,$//')
# get server ip address
IPADDR=$(ip -4 a show eno1 |grep -o "inet [^/]*" | awk '{print $2}')

declare -gA disks

# Parse partition name and limitaion from JSON file and save them to an array
while read -r disk limit;
do
	disks[$disk]=$limit
done < <(egrep "name|limit" $JSON |sed -e 's/"//g' | sed -e 's/:/ /g' | sed ':a;N;$!ba;s/,\n/ /g' | awk '{print $2, $4}')

# Comnine partitions name to regular expression 
# for watching the percentage of disk space that is used
REGEX=""
index=0
for i in ${!disks[@]} 
do 
	REGEX+="^\\$i$"
	index+=1
	if [ "$index" -lt "${#disks[@]}" ];
	then
		REGEX+="|"
	fi
done

# Check the percentage of disk space that is used 
# set SEND true if the percentage is larger than limitation
SEND=false
DF=$(df -H | grep -vE '^Filesystem|tmpfs|cdrom' | awk "\$6 ~ /$REGEX/ { print \$0 }" | awk '{printf "%-8s %s\n", $5, $6}')

while read -r usep mount;
do
	usage=$(echo $usep | cut -d '%' -f1) 
	if [ "$usage" -gt "${disks[$mount]}" ];
	then
		SEND=true
	fi
done < <(df -H | grep -vE '^Filesystem|tmpfs|cdrom' | awk "\$6 ~ /$REGEX/ { print \$5, \$6 }")

echo $ADMIN
#echo $REGEX
#echo $SEND

# If SEND is true, send Alert mail to ADMIN
if [ "$SEND" = true ]; 
then
    echo -e "Running out of space on $(hostname)($IPADDR) as on $(date)\n\nUSE%\tmount\n$DF" |
    mail -s "Alert: $(hostname)($IPADDR) Run out of space" "$ADMIN"
fi
