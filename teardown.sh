#!/usr/bin/env bash
kubectl delete -f nfs-bucket-server-rc.yaml
kubectl delete -f nfs-bucket-server-service.yaml
kubectl delete -f nfs-bucket-pv.yaml
kubectl delete -f nfs-bucket-pvc.yaml
kubectl delete -f nfs-test.yaml
