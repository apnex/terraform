#!/bin/bash
KUBECONFIG="--kubeconfig=/home/admin/kube_config"
PODNAME=$(kubectl ${KUBECONFIG} get pods -o json | jq -r '.items[] | select(.metadata.name | contains("frr")).metadata.name')
kubectl ${KUBECONFIG} exec -it ${PODNAME} -- vtysh
