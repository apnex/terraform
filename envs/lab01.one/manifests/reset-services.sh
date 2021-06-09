#!/bin/bash
echo "Removing stale (exited) docker containers..."
docker rm -v $(docker ps -a -q -f status=exited)

## check / create vlan 5 interface
INTERNALNIC="eth1"
if ! RESULT=$(nmcli connection show id eth1.5) ; then
	nmcli connection add type vlan con-name ${INTERNALNIC}.5 dev ${INTERNALNIC} id 5
	nmcli connection modify ${INTERNALNIC}.5 \
		ipv4.method manual \
		ipv4.addresses 172.16.5.1/24 \
		ipv4.never-default yes
	nmcli connection up ${INTERNALNIC}.5
fi
nmcli connection show

## check for iptables NAT rule
NATRULE="POSTROUTING -o eth0 -j MASQUERADE"
if [[ $(iptables -t nat -S POSTROUTING | grep "${NATRULE}") ]]; then
	echo "POSTROUTING SNAT already configured for eth0"
else
	echo "Configuring POSTROUTING SNAT for eth0"
	iptables -t nat -A ${NATRULE}
fi

## determine IPV4 ADDRESS of default route interface
ETH=$(route | grep ^default | sed "s/.* //")
IPADDRESS=$(ip addr show "${ETH}" | grep inet\ | awk '{print $2}' | cut -d/ -f1)

## kubectl healthcheck
KUBECONFIG="--kubeconfig=/root/.kube/config"
echo "[[ Kubernetes API Healthcheck ]]"
HEALTHY=$(kubectl ${KUBECONFIG} -n kube-system get pods 2>/dev/null)
while [[ -z ${HEALTHY} ]]; do
	echo "socket [ localhost:6443 ] api [ no response ]"
	sleep 10
	HEALTHY=$(kubectl ${KUBECONFIG} -n kube-system get pods 2>/dev/null)
done
echo "socket [ localhost:6443 ] api [ healthy ]"

## clear "NodeAffinity" errors
echo "Clearing [ NodeAffinity ] errored pods"
kubectl ${KUBECONFIG} delete pods --field-selector status.phase=Failed --all-namespaces

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
printf "${METALPOOL}" | kubectl ${KUBECONFIG} apply -f -
kubectl ${KUBECONFIG} -n metallb-system delete pods --all
