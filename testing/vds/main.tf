data "vsphere_datacenter" "datacenter" {
	name = "lab01"
}

data "vsphere_host" "host" {
	for_each	= toset(var.nodes)
	name		= each.key
	datacenter_id   = data.vsphere_datacenter.datacenter.id
}

resource "vsphere_distributed_virtual_switch" "dvs" {
	name		= "fabric"
	datacenter_id	= data.vsphere_datacenter.datacenter.id
	uplinks		= ["uplink1","uplink2"]
	active_uplinks	= ["uplink2"]
	standby_uplinks	= []
	max_mtu		= 9000
	dynamic "host" {
		for_each	= toset(var.nodes)
		content {
			host_system_id = data.vsphere_host.host[host.value].id
			devices        = var.network_interfaces
		}
	}
}

resource "vsphere_distributed_port_group" "pgs" {
	for_each			= var.portgroups
	name                            = each.key
	allow_forged_transmits		= true
	allow_mac_changes		= true
	allow_promiscuous		= false
	distributed_virtual_switch_uuid	= vsphere_distributed_virtual_switch.dvs.id
	vlan_id				= each.value
}
