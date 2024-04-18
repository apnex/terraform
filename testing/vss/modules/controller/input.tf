terraform {
	required_providers {
		vsphere = "~> 1.15.0"
	}
}

variable "name"			{}
variable "datacenter"		{}
variable "resource_pool"	{}
variable "datastore"		{}
variable "network"		{}
variable "bootfile_url"		{}
variable "bootfile_name"	{}
variable "private_key"		{}
variable "public_key"		{}
