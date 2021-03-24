locals {
	portgroups = {
		"pg-mgmt"	= 0,
		"pg-vmotion"	= 11,
		"pg-vsan"	= 12
	}
	clusters = [
		{
			name	= "cmp"
			nodes	= [
				"esx21.lab02.mel",
				"esx22.lab02.mel",
				"esx23.lab02.mel"
			]
		},
		{
			name	= "edge"
			nodes	= [
				"esx24.lab02.mel"
			]
		}
	]
	# create a map from all nodes
	nodes = merge([
		for cluster in local.clusters: {
			for node in cluster.nodes: node => cluster.name
		}
	]...)
}

# create a new datacenter
resource "vsphere_datacenter" "datacenter" {
	name = "lab02"
}

## foreach cluster, create cluster
resource "vsphere_compute_cluster" "cluster" {
	for_each		= toset(local.clusters[*].name)
	name			= each.key
	datacenter_id		= vsphere_datacenter.datacenter.moid
	drs_enabled		= true
	drs_automation_level	= "partiallyAutomated"
	ha_enabled		= false
	lifecycle {
		ignore_changes = [
			host_system_ids
		]
	}
	depends_on = [
		vsphere_datacenter.datacenter
	]
}

# foreach host, get thumbprint
data "vsphere_host_thumbprint" "thumbprint" {
        for_each        = local.nodes
        address         = each.key
        insecure        = true
}

# foreach host, attach to cluster
resource "vsphere_host" "host" {
	for_each	= local.nodes
	hostname	= each.key
	username	= "root"
	password	= "VMware1!SDDC"
	thumbprint	= data.vsphere_host_thumbprint.thumbprint[each.key].id
	cluster		= vsphere_compute_cluster.cluster[each.value].id
}

# create switch
resource "vsphere_distributed_virtual_switch" "dvs" {
	name		= "fabric"
	datacenter_id	= vsphere_datacenter.datacenter.moid
	uplinks		= ["uplink1","uplink2"]
	active_uplinks	= ["uplink2"]
	standby_uplinks	= []
	max_mtu		= 9000
	dynamic "host" {
		for_each = local.nodes
		content {
			host_system_id = vsphere_host.host[host.key].id
			devices        = var.network_interfaces
		}
	}
}

# create portgroups
resource "vsphere_distributed_port_group" "pgs" {
	for_each			= local.portgroups
	name                            = each.key
	allow_forged_transmits		= true
	allow_mac_changes		= true
	allow_promiscuous		= false
	distributed_virtual_switch_uuid	= vsphere_distributed_virtual_switch.dvs.id
	vlan_id				= each.value
}

resource "vsphere_vnic" "vmk1" {
	count			= length(keys(local.nodes))
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
	count			= length(keys(local.nodes))
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
