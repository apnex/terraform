terraform {
	backend "local" {
		path = "./terraform.tfstate"
	}
}

# create VAPP
# create Control-Node
module "controller" {
	source = "../../modules/controller"

	# vsphere provider details
	vsphere_server		= "vcenter.core.syd"
	vsphere_user		= "administrator@vsphere.local"
	vsphere_password	= "VMware1!SDDC"
}
