#!/bin/bash
PODNAME=$(kubectl get pods -o json | jq -r '.items[] | select(.metadata.name | contains("dns")).metadata.name')
kubectl exec -it ${PODNAME} -- bind-cli zone.list
