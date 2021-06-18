#!/bin/bash

## references
# https://projectcontour.io/guides/gateway-api/
# https://gateway-api.sigs.k8s.io/

## install contour operator
kubectl apply -f https://projectcontour.io/quickstart/operator.yaml
