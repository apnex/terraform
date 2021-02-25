#!/bin/bash

## clear tfstate
rm -rf ./terraform*

## import and read cluster
terraform import -allow-missing-config vsphere_compute_cluster.cmp /lab01/host/cmp

## loop over hosts and import host_switch and vmk0
for HOST in $(terraform show -json | jq -r '.values.root_module.resources[0].values.host_system_ids[]'); do
	echo "Importing vSwitch0 on [ $HOST ]"
	terraform import -allow-missing-config vsphere_host_virtual_switch.vswitch_${HOST} tf-HostVirtualSwitch:${HOST}:vSwitch0
	echo "Importing vmk0 on [ $HOST ]"
	terraform import -allow-missing-config vsphere_vnic.vmk0_${HOST} ${HOST}_vmk0
done

## remove cluster from state
terraform state rm vsphere_compute_cluster.cmp

## write out main file??
#terraform show -json | jq --tab . > new.tf.json
terraform show -no-color | sed -e '/^[[:blank:]]*id/d' > new.tf
## heredoc?
