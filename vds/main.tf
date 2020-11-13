	#version			= "~> 1.23.0" # errors with > 1.24
provider "vsphere" {
	vsphere_server		= "vcenter.lab01"
	user			= "administrator@vsphere.local"
	password		= "VMware1!SDDC"
	allow_unverified_ssl	= true
}

variable "nodes" {
	default = [
		"esx11.lab01",
		"esx12.lab01",
		"esx13.lab01",
	]
}

variable "network_interfaces" {
	default = [
		"vmnic1"
	]
}

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
	uplinks		= ["uplink2"]
	active_uplinks	= ["uplink2"]
	standby_uplinks	= []
	max_mtu		= 9000

	host {
		host_system_id = data.vsphere_host.host["esx11.lab01"].id
		devices        = var.network_interfaces
	}
	host {
		host_system_id = data.vsphere_host.host["esx12.lab01"].id
		devices        = var.network_interfaces
	}
	host {
		host_system_id = data.vsphere_host.host["esx13.lab01"].id
		devices        = var.network_interfaces
	}
}

resource "vsphere_distributed_port_group" "pg-mgmt" {
	name                            = "pg-mgmt"
	allow_forged_transmits		= true
	allow_mac_changes		= true
	allow_promiscuous		= false
	distributed_virtual_switch_uuid = vsphere_distributed_virtual_switch.dvs.id
	vlan_id = 0
}
resource "vsphere_distributed_port_group" "pg-vmotion" {
	name                            = "pg-vmotion"
	allow_forged_transmits		= true
	allow_mac_changes		= true
	allow_promiscuous		= false
	distributed_virtual_switch_uuid = vsphere_distributed_virtual_switch.dvs.id
	vlan_id = 11
}
resource "vsphere_distributed_port_group" "pg-vsan" {
	name                            = "pg-vsan"
	allow_forged_transmits		= true
	allow_mac_changes		= true
	allow_promiscuous		= false
	distributed_virtual_switch_uuid = vsphere_distributed_virtual_switch.dvs.id
	vlan_id = 12
}
