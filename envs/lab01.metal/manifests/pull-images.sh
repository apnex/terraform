#!/bin/bash

APPS=$(kubectl get pods -A -o json)
IFS=$'\n'
for APP in $(echo "${APPS}" | jq -c '.items[]'); do
	NAME=$(echo "${APP}" | jq -r '.spec.containers[0].image')
	echo "${NAME}"
	docker pull "${NAME}"
done
