## obtain default local ESX host ids
data "vsphere_datacenter" "datacenter" {}
data "vsphere_resource_pool" "pool" {}
data "vsphere_host" "esx" {
	datacenter_id = data.vsphere_datacenter.datacenter.id
}

## create new vSwitch1
resource "vsphere_host_virtual_switch" "switch" {
	name           = "vSwitch1"
	host_system_id = data.vsphere_host.esx.id
	network_adapters = ["vmnic3"]
	active_nics  = ["vmnic3"]
	standby_nics = []
}

## create portgroup 'external'
resource "vsphere_host_port_group" "external" {
	name                = "external"
	host_system_id      = data.vsphere_host.esx.id
	virtual_switch_name = vsphere_host_virtual_switch.switch.name
}

# create dns server
module "controller" {
	source = "./modules/controller"
	depends_on = [
		vsphere_host_port_group.external
	]

	## inputs
	name		= "router"
	datacenter	= data.vsphere_datacenter.datacenter.id
	resource_pool	= data.vsphere_resource_pool.pool.id
	datastore	= "datastore1"
	network		= "external"
	bootfile_url	= "http://labops.sh/library/labops.centos.stage2.iso"
	bootfile_name	= "labops.centos.stage2.iso"
	private_key	= "controller.key"
	public_key	= "controller.key.pub"
}
