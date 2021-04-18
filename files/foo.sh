#!/bin/bash
filecount=0
while [ $filecount -lt 100 ] ; do
    filesize=$RANDOM
    filesize=$(($filesize+1024))
    base64 /dev/urandom | 
    head -c "$filesize" > file${filecount}.$RANDOM
    ((filecount++))
done
