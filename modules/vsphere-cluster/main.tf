# This module
### constructs the empty "cmp" cluster first
### joins the ESX hosts directly to the "cmp" cluster using "cluster" attribute
### cmp.host_cluster_ids needs to be ignored for changes, as it is modified by the provider after the fact

locals {
	nodes = [
		"esx21.lab02.mel",
		"esx22.lab02.mel",
		"esx23.lab02.mel",
	]
}

data "vsphere_datacenter" "datacenter" {
	name = "lab02"
}

data "vsphere_host_thumbprint" "thumbprint" {
	for_each	= toset(var.cluster.nodes)
	address		= each.key
	insecure	= true
}


resource "vsphere_compute_cluster" "cluster" {
	name			= var.cluster.name
	datacenter_id		= data.vsphere_datacenter.datacenter.id
	drs_enabled		= true
	drs_automation_level	= "partiallyAutomated"
	ha_enabled		= false
	lifecycle {
		ignore_changes = [
			host_system_ids
		]
	}

}

resource "vsphere_host" "host" {
	for_each	= toset(var.cluster.nodes)
	hostname	= each.key
	username	= "root"
	password	= "VMware1!SDDC"
	thumbprint	= data.vsphere_host_thumbprint.thumbprint[each.key].id
	cluster 	= vsphere_compute_cluster.cluster.id
}

resource "vsphere_distributed_virtual_switch" "dvs" {
	name		= "fabric"
	datacenter_id	= data.vsphere_datacenter.datacenter.id
	uplinks		= ["uplink1","uplink2"]
	active_uplinks	= ["uplink2"]
	standby_uplinks	= []
	max_mtu		= 9000
	dynamic "host" {
		for_each	= toset(var.cluster.nodes)
		content {
			host_system_id = vsphere_host.host[host.value].id
			devices        = var.network_interfaces
		}
	}
}

resource "vsphere_distributed_port_group" "pgs" {
	for_each			= var.cluster.portgroups
	name                            = each.key
	allow_forged_transmits		= true
	allow_mac_changes		= true
	allow_promiscuous		= false
	distributed_virtual_switch_uuid	= vsphere_distributed_virtual_switch.dvs.id
	vlan_id				= each.value
}

resource "vsphere_vnic" "vmk1" {
	count			= length(var.cluster.nodes)
	host			= values(vsphere_host.host)[count.index].id
	distributed_switch_port	= vsphere_distributed_virtual_switch.dvs.id
	distributed_port_group	= values(vsphere_distributed_port_group.pgs)[1].id
	ipv4 {
		ip	= "172.16.11.${count.index + 121}"
		netmask	= "255.255.255.0"
		gw	= "172.16.11.1"
	}
	netstack	= "vmotion"
}

resource "vsphere_vnic" "vmk2" {
	count			= length(var.cluster.nodes)
	host			= values(vsphere_host.host)[count.index].id
	distributed_switch_port	= vsphere_distributed_virtual_switch.dvs.id
	distributed_port_group	= values(vsphere_distributed_port_group.pgs)[2].id
	ipv4 {
		ip	= "172.16.12.${count.index + 121}"
		netmask	= "255.255.255.0"
		gw	= "172.16.12.1"
	}
	netstack	= "defaultTcpipStack"
	depends_on = [ # ensure that vmk2 is for vsan
		vsphere_vnic.vmk1
	]
}
