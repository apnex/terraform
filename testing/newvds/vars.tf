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

variable "nodes" {
	default = [
		"esx11.lab01",
		"esx12.lab01",
		"esx13.lab01",
	]
}

variable "network_interfaces" {
	default = [
		"vmnic1"
	]
}

variable "portgroups" {
	type = map
	default = {
		"pg-mgmt"	= 0,
		"pg-vmotion"	= 11,
		"pg-vsan"	= 12
	}
}
