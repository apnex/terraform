variable "cluster" {}
variable "network_interfaces" {
	default = [
		"vmnic1"
	]
}
variable "portgroups" {
	default = {
		"pg-mgmt"	= 0,
		"pg-vmotion"	= 11,
		"pg-vsan" 	= 12
	}
}

