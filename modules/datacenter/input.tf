variable "name" {}
variable "vsphere_server" {}
variable "user" {}
variable "password" {}

provider "vsphere" {
	#version		= "~> 1.23.0" # errors with > 1.24
	vsphere_server		= var.vsphere_server
	user			= var.user
	password		= var.password
	allow_unverified_ssl	= true
}

variable "nodes" {
	default = [
		"esx11.lab01",
		"esx12.lab01",
		"esx13.lab01",
	]
}
