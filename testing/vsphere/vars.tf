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

variable "datastore" {
	default = "datastore1"
}

variable "vmw" {
	default = {
		network = "pg-trunk"
		datastore = "datastore1"
		nodes = [
			{
				name = "esx11"
			}
		]
	}
}
