terraform {
	backend "local" {
		path = "./terraform.tfstate"
	}
}

provider "vsphere" {
	#version		= "~> 1.23.0" # errors with > 1.24
	vsphere_server		= "vcenter.lab01"
	user			= "administrator@vsphere.local"
	password		= "VMware1!SDDC"
	allow_unverified_ssl	= true
}
