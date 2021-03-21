terraform {
	backend "local" {
		path = "./terraform.tfstate"
	}
}

provider "vsphere" {
	vsphere_server		= "vcenter.lab01"
	user			= "administrator@vsphere.local"
	password		= "VMware1!SDDC"
	allow_unverified_ssl	= true
}
