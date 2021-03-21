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
	vsphere_server		= "vcenter.lab"
	user			= "administrator@vsphere.local"
	password		= "ObiWan1!"
	allow_unverified_ssl	= true
}

variable "vmw" {
	default = {
		lab_id		= "2"
	}
}
