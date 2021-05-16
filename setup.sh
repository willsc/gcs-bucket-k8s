#!/bin/bash

echo "Running startup script"
export GOOGLE_APPLICATION_CREDENTIALS=/accounts/key.json
[ -f ${GOOGLE_APPLICATION_CREDENTIALS} ] && echo "Credentials exist." || echo "Credentials does not exist."

echo "Running fuse, bucket is ${BUCKET}"
mount -t gcsfuse -o rw,noatime,_netdev,user,implicit_dirs ${BUCKET} /exports

function start()
{

    unset gid
    # accept "-G gid" option
    while getopts "G:" opt; do
        case ${opt} in
            G) gid=${OPTARG};;
        esac
    done
    shift $(($OPTIND - 1))

    # prepare /etc/exports
    for i in "$@"; do
        # fsid=0: needed for NFSv4
        echo "$i *(rw,fsid=0,insecure,no_root_squash)" >> /etc/exports
        if [ -v gid ] ; then
            chmod 070 $i
            chgrp $gid $i
        fi
        # move index.html to here
        #/bin/cp /tmp/index.html $i/
        #chmod 644 $i/index.html
        echo "Serving $i"
    done

    # start rpcbind if it is not started yet
    /usr/sbin/rpcinfo 127.0.0.1 > /dev/null; s=$?
    if [ $s -ne 0 ]; then
       echo "Starting rpcbind"
       /sbin/rpcbind -w
    fi

    mount -t nfsd nfds /proc/fs/nfsd

    # -V 3: enable NFSv3
    /usr/sbin/rpc.mountd -N 2 -V 3

    /usr/sbin/exportfs -r
    # -G 10 to reduce grace time to 10 seconds (the lowest allowed)
    /usr/sbin/rpc.nfsd -G 10 -N 2 -V 3
    /sbin/rpc.statd --no-notify
    echo "NFS started"
    showmount -e
}

function stop()
{
    echo "Stopping NFS"

    /usr/sbin/rpc.nfsd 0
    /usr/sbin/exportfs -au
    /usr/sbin/exportfs -f

    kill $( pidof rpc.mountd )
    umount /proc/fs/nfsd
    echo > /etc/exports

    fusermount -u ${BUCKET}
    exit 0
}


trap stop TERM

start "$@"

# Ugly hack to do nothing and wait for SIGTERM
while true; do
    sleep 5
done

