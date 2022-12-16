# diskAlert
Send mail alert if the disks on server run out of space 

### Configure JSON file for mail addresses and disks
1. add mail address JSON string to 'admin' array

2. add disk objects to 'disk' array with 2 properties 'name' as the mount point and 'limit' as the percentage of the disk quota.

If the quota is surpassed the 'limit', the shell script send warning message to mail addresses in the 'admin' array.

### Configure the path of JSON file in shell script
modify the value of 'JSON' to the path of your JSON configure file.
