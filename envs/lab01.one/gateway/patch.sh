#!/bin/bash

PATCH=$(jq -nc '{
	"metadata": {
		"annotations": {
			"metallb.universe.tf/allow-shared-ip": "host"
		}
	},
	"spec": {
		"externalTrafficPolicy": "Cluster"
	}
}')
printf "${PATCH}" | jq --tab .
kubectl patch svc envoy -n projectcontour --type merge -p "${PATCH}"
