terraform {
	backend "local" {
		path = "./terraform.tfstate"
	}
}

provider "vsphere" {
	#version		= "~> 1.23.0"
	vsphere_server		= "vcenter.lab01"
	user			= "administrator@vsphere.local"
	password		= "VMware1!SDDC"
	allow_unverified_ssl	= true
}

variable "nodes" {
	default = [
		"esx11.lab01",
		"esx12.lab01",
		"esx13.lab01"
	]
}
