provider "vsphere" {
	vsphere_server		= "vcenter.lab02.mel"
	user			= "administrator@vsphere.local"
	password		= "VMware1!SDDC"
	allow_unverified_ssl	= true
}

data "vsphere_datacenter" "datacenter" {
	name		= "lab02"
}

data "vsphere_host" "host" {
	name		= "esx24.lab02.mel"
	datacenter_id	= data.vsphere_datacenter.datacenter.id
}

resource "vsphere_vmfs_datastore" "datastore" {
	name		= "terraform-test"
	host_system_id	= data.vsphere_host.host.id

	disks = [
		"mpx.vmhba0:C0:T2:L0"
	]
}
