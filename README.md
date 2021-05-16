# gcs-bucket-k8s

Example config on how to create an NFS server that uses a bucket as its share.

Uses gcsfuse to mount the share internally.

Install
First, you need to:

Create a secret volume (https://kubernetes.io/docs/concepts/configuration/secret/). This SA should have access to the bucket you want to mount. This is all in the replicationcontroller: nfs-bucket-server-rc. You should change the sa-THE-SERVICE-ACCOUNT name to reflect this. The secret mount should have this file: /accounts/key.json

UPDATE the environment variable in nfs-bucket-server-rc:BUCKET to the bucket you want to share. Use bucket name only, dont prefix with gs://
note:

Create secret for the credentials

```
kubectl create secret generic terraform --from-file=./key.json -n nfs-bucket

```



Then apply these scripts in this order:
```
kubectl apply -f yaml/nfs-bucket-server-rc.yaml
kubectl apply -f yaml/nfs-bucket-server-service.yaml
kubectl apply -f yaml/nfs-bucket-pv.yaml
kubectl apply -f yaml/nfs-bucket-pvc.yaml
```
This job lists the content of the bucket (for debugging)

kubectl apply -f yaml/nfs-bucket-pvc.yaml
To build from dockerfile
```
docker build -t nfs-bucket-server:1.0 .
docker push nfs-bucket-server:1.0 .
```
Notes
You can use the GCSFUSE_PARAMS environment variable for adding additional parameters to the mounting process.

setup.sh
```

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


```




More Info
Based on various resources I found:

https://estl.tech/multi-writer-file-storage-on-gke-6d044ec96a46
https://github.com/alphayax/docker-volume-nfs
