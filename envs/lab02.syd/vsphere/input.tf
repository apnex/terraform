terraform {
	backend "local" {
		path = "./terraform.tfstate"
	}
}

#data "terraform_remote_state" "stage0" {
#	backend = "local"
#	config = {
#		path = "../dns/terraform.tfstate"
#	}
#}

provider "vsphere" {
	vsphere_server		= "vcenter.core.syd"
	user			= "administrator@vsphere.local"
	password		= "VMware1!SDDC"
	allow_unverified_ssl	= true
}

variable "vmw" {
	default = {
		lab_id		= "2"
	}
}
