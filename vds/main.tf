provider "vsphere" {
	version			= "~> 1.23.0" # errors with > 1.24
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
	name		= "aterraform-test-dvs"
	datacenter_id	= data.vsphere_datacenter.datacenter.id
	uplinks		= ["uplink1", "uplink2"]
	active_uplinks	= ["uplink1"]

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

