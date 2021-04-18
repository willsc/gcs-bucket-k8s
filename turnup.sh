#!/usr/bin/env bash


kubectl apply -f nfs-bucket-server-rc.yaml
kubectl apply -f nfs-bucket-server-service.yaml
kubectl apply -f nfs-bucket-pv.yaml
kubectl apply -f nfs-bucket-pvc.yaml
