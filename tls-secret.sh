#!/bin/bash
kubectl config use-context k3d-local
kubectl -n $NAMESPACE create secret tls $SECRETNAME --key ./certs/key.pem --cert ./certs/cert.pem