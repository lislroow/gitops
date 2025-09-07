#!/usr/bin/env bash

kubectl apply -f nexus-configmap.yaml
kubectl apply -f nexus-deployment.yaml
kubectl apply -f nexus-pvc.yaml
kubectl apply -f nexus-service.yaml
