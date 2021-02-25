variable "vsphere_user" {}
variable "vsphere_password" {}
variable "vsphere_server" {}
terraform {
	backend "local" {
		path = "./terraform.tfstate"
	}
	required_providers {
		vsphere = ">= 1.23.0"
	}
}

provider "vsphere" {
	user                 = var.vsphere_user
	password             = var.vsphere_password
	vsphere_server       = var.vsphere_server
	allow_unverified_ssl = true
}

variable "nodes" {
	type = map
	default = {
		"onprem-web01"	= 1,
		"onprem-web02"	= 1,
		"onprem-web03"	= 1
	}
}
