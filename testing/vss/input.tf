terraform {
	backend "local" {
		path = "./terraform.tfstate"
	}
	required_providers {
		vsphere = ">= 1.15.0"
	}
}

provider "vsphere" {
	vsphere_server		= "136.144.62.202"
	user			= "root"
	password		= "pS_B2L54{;"
	allow_unverified_ssl	= true
}
