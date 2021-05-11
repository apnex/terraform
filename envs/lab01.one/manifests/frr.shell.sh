#!/bin/bash
PODNAME=$(kubectl get pods -o json | jq -r '.items[] | select(.metadata.name | contains("frr")).metadata.name')
kubectl exec -it ${PODNAME} -- vtysh
