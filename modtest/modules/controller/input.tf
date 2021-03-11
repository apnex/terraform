terraform {
	backend "local" {
		path = "./terraform.tfstate"
	}
	required_providers {
		vsphere = ">= 1.23.0"
	}
}

variable "vsphere_user" {}
variable "vsphere_password" {}
variable "vsphere_server" {}
provider "vsphere" {
	user                 = var.vsphere_user
	password             = var.vsphere_password
	vsphere_server       = var.vsphere_server
	allow_unverified_ssl = true
}

variable "vmw" {
	default = {
		lab_id = 3
		network = "pg-mgmt"
		datastore = "ds-esx04"
		bootfile_url = "http://labops.sh/library/labops.centos.stage2.iso"
		bootfile_name = "labops.centos.stage2.iso"
		controller = {
			name = "router"
		}
	}
}

