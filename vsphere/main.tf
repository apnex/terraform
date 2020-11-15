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

data "vsphere_host_thumbprint" "thumbprint" {
	for_each = toset(local.nodes)
	address = each.key
	insecure = true
}

resource "vsphere_host" "hosts" {
	for_each = toset(local.nodes)
	hostname = each.key
	username = "root"
	password = "VMware1!SDDC"
	thumbprint = data.vsphere_host_thumbprint.thumbprint[each.key].id
	cluster  = data.vsphere_compute_cluster.cmp.id
}
