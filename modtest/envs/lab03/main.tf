terraform {
	backend "local" {
		path = "./terraform.tfstate"
	}
}

module "newdc" {
	source = "../../modules/datacenter"
	name = "prod-dc-02"

	# vsphere provider details
	vsphere_server	= "vcenter.lab03.syd"
	user		= "administrator@vsphere.local"
	password	= "VMware1!SDDC"
}
