data "vsphere_datacenter" "datacenter" {
	name		= "lab01"
}

data "vsphere_host" "host" {
	count		= length(var.nodes)
	name		= var.nodes[count.index]
	datacenter_id	= data.vsphere_datacenter.datacenter.id
}

data "vsphere_distributed_virtual_switch" "dvs" {
	name		= "fabric"
	datacenter_id	= data.vsphere_datacenter.datacenter.id
}
