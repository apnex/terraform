terraform {
	required_providers {
		vsphere = ">= 1.23.0"
	}
}

variable "prefix"		{}
variable "esx_id"		{}
variable "esx_name"		{}
variable "esx_network"		{}
variable "esx_datastore"	{}
variable "datacenter"		{}
variable "bootfile_url"		{}
