data "vsphere_datacenter" "datacenter" {
	name = "lab01"
}

data "vsphere_distributed_virtual_switch" "dvs" {
	name		= "fabric"
	datacenter_id	= data.vsphere_datacenter.datacenter.id
}

resource "vsphere_distributed_port_group" "pgs" {
	for_each			= var.portgroups
	name                            = each.key
	allow_forged_transmits		= true
	allow_mac_changes		= true
	allow_promiscuous		= false
	distributed_virtual_switch_uuid	= data.vsphere_distributed_virtual_switch.dvs.id
	vlan_id				= each.value
}
