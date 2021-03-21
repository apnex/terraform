provider "vsphere" {
	vsphere_server		= "vcenter.lab01"
	user			= "administrator@vsphere.local"
	password		= "VMware1!SDDC"
	allow_unverified_ssl	= true
}

data "vsphere_datacenter" "datacenter" {
	name = "lab01"
}

data "vsphere_host" "host" {
	name          = "esx11.lab01"
	datacenter_id = data.vsphere_datacenter.datacenter.id
}

resource "vsphere_host_virtual_switch" "switch" {
	active_nics               = [
		"vmnic1"
	]
	host_system_id            = "host-1054"
	name                      = "vSwitch0"
	network_adapters          = [
		"vmnic1"
	]
	standby_nics              = []
}
