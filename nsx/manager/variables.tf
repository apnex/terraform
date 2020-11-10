variable "datacenter" {}
variable "cluster" {}
variable "pool" {}
variable "datastore" {}
variable "host" {}
variable "dvs" {
	default = "fabric"
}
variable "network" {
	default = "pg-mgmt"
}
