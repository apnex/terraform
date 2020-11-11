provider "vsphere" {
	version			= "~> 1.23.0" # errors with > 1.24
	vsphere_server		= "vcenter.lab01"
	user			= "administrator@vsphere.local"
	password		= "VMware1!SDDC"
	allow_unverified_ssl	= true
}

data "vsphere_datacenter" "datacenter" {
	name = "lab01"
}

data "vsphere_compute_cluster" "cmp" {
	name          = "cmp"
	datacenter_id = data.vsphere_datacenter.datacenter.id
}

locals {
	nodes = [
		"esx11.lab01",
		"esx12.lab01",
		"esx13.lab01",
	]
}

resource "vsphere_host" "hosts" {
	for_each = toset(local.nodes)
	hostname = each.key
	username = "root"
	password = "VMware1!SDDC"
	cluster  = data.vsphere_compute_cluster.cmp.id
}
