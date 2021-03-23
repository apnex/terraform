terraform {
	backend "local" {
		path = "./terraform.tfstate"
	}
}

provider "vsphere" {
	vsphere_server		= "vcenter.lab02.mel"
	user			= "administrator@vsphere.local"
	password		= "VMware1!SDDC"
	allow_unverified_ssl	= true
}

variable "nodes" {
	type = list(string)
	default = [
		"esx21.lab02.mel",
		"esx22.lab02.mel",
		"esx23.lab02.mel",
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
