variable "datacenter" {}
variable "cluster" {}
variable "datastore" {}
variable "host" {}
variable "dvs" {
	default = "fabric"
}
variable "network" {
	default = "pg-mgmt"
}
variable "vsphere_user" {}
variable "vsphere_password" {}
variable "vsphere_server" {}
