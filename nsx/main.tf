provider "vsphere" {
	version        = "~> 1.23.0" 
	vsphere_server = var.vsphere_server
	user           = var.vsphere_user
	password       = var.vsphere_password
	allow_unverified_ssl = true
}

module "nsx-manager" {
	source		= "./manager"
	datacenter	= var.datacenter
	cluster		= var.cluster
	pool		= var.pool
	datastore	= var.datastore
	host		= var.host
	dvs		= "fabric"
	network		= "pg-mgmt"
}
