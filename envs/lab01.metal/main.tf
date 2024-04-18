terraform {
	backend "local" {
		path = "./terraform.tfstate"
	}
}

locals {
	lab			= "lab0${var.vmw.lab_id}"	
}

# vsphere vapp base
data "vsphere_datacenter" "datacenter" {
	name			= var.vmw.datacenter
}

data "vsphere_compute_cluster" "cluster" {
	name			= var.vmw.cluster
	datacenter_id		= data.vsphere_datacenter.datacenter.id
}

resource "vsphere_vapp_container" "lab" {
	name			= local.lab
	parent_resource_pool_id	= data.vsphere_compute_cluster.cluster.resource_pool_id
	lifecycle {
		ignore_changes = [
			parent_folder_id
		]
	}
}

# create Control-Node
module "controller" {
	source = "../../modules/controller"
	depends_on = [
		vsphere_vapp_container.lab
	]

	vmw			= var.vmw
	## dont pass directly - translate into specific vars
}
