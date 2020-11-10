provider "vsphere" {
	version        = "~> 1.23.0" 
	vsphere_server = var.vsphere_server
	user           = var.vsphere_user
	password       = var.vsphere_password
	allow_unverified_ssl = true
}

module "nsx-manager" {
	source		= "./module-nsx-manager"
	datacenter	= var.datacenter
	cluster		= var.cluster
	datastore	= var.datastore
	host		= var.host
	dvs		= "fabric"
	network		= "pg-mgmt"
}
