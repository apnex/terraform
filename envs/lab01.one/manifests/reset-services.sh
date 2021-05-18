#!/bin/bash

## read values from shell
read -p "ADDRESS--[ e.g 10.79.231.1   ]-: " ADDRESS
read -p "MASKLEN--[ e.g 24            ]-: " MASKLEN
read -p "GATEWAY--[ e.g 10.79.231.254 ]-: " GATEWAY
read -p "DNS------[ e.g 10.79.0.132   ]-: " DNS
#ADDRESS="10.79.231.1"
#MASKLEN="24"
#GATEWAY="10.79.231.254"
#DNS="10.79.0.132"

## determine IPV4 ADDRESS of default route interface
#ETH=$(route | grep ^default | sed "s/.* //")
#ADDRESS=$(ip addr show "${ETH}" | grep inet\ | awk '{print $2}' | cut -d/ -f1)

## Clear hard-coded MAC and configure interface IP
nmcli connection modify eth0 802-3-ethernet.mac-address ""
nmcli connection modify eth0 ipv4.method manual
nmcli connection modify eth0 ipv4.addresses "${ADDRESS}/${MASKLEN}"
nmcli connection modify eth0 ipv4.gateway "${GATEWAY}"
nmcli connection modify eth0 ipv4.dns "${DNS}"
nmcli connection up eth0

## kubectl healthcheck
echo "[[ Kubernetes API Healthcheck ]]"
HEALTHY=$(kubectl -n kube-system get pods 2>/dev/null)
while [[ -z ${HEALTHY} ]]; do
	echo "socket [ localhost:6443 ] api [ no response ]"
	sleep 10
	HEALTHY=$(kubectl -n kube-system get pods 2>/dev/null)
done
echo "socket [ localhost:6443 ] api [ healthy ]"

## clear "NodeAffinity" errors
echo "Clearing [ NodeAffinity ] errored pods"
kubectl delete pods --field-selector status.phase=Failed --all-namespaces

## configure and reset MetalLb
echo "Restarting MetalLB with new IP [ ${IPADDRESS} ]"
read -r -d '' METALPOOL <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - ${IPADDRESS}/32
EOF
echo "${METALPOOL}"
printf "${METALPOOL}" | kubectl apply -f -
kubectl -n metallb-system delete pods --all
