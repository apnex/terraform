terraform {
	required_providers {
		vsphere = "= 1.23.0"
	}
}
provider "vsphere" {
	user                 = var.vsphere_user
	password             = var.vsphere_password
	vsphere_server       = var.vsphere_server
	allow_unverified_ssl = true
}
 
data "vsphere_datacenter" "dc" {
	name = var.data_center
}

data "vsphere_compute_cluster" "cluster" {
	name          = var.cluster
	datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_datastore" "datastore" {
	name          = var.workload_datastore
	datacenter_id = data.vsphere_datacenter.dc.id
}
 
data "vsphere_resource_pool" "pool" {
	name          = var.compute_pool
	datacenter_id = data.vsphere_datacenter.dc.id
}
 
data "vsphere_host" "host" {
	name          = "10.2.2.4"
	datacenter_id = data.vsphere_datacenter.dc.id
}
 
data "vsphere_network" "network" {
	name          = "ao-mgmt"
	datacenter_id = data.vsphere_datacenter.dc.id
}
 
resource "vsphere_virtual_machine" "avi-c01" {
	name             = "avi-c01"
	resource_pool_id = data.vsphere_resource_pool.pool.id
	datastore_id     = data.vsphere_datastore.datastore.id
	datacenter_id    = data.vsphere_datacenter.dc.id
	host_system_id   = data.vsphere_host.host.id
	wait_for_guest_net_timeout = 0
	wait_for_guest_ip_timeout  = 0
 
	ovf_deploy {
		local_ovf_path = "./controller.ova"
		disk_provisioning = "thin"
		ovf_network_map = {
			"Management" = data.vsphere_network.network.id
		}
	}
 
	vapp {
		properties = {
			"mgmt-ip"	= "172.21.10.109",
			"mgmt-mask"	= "255.255.255.0",
			"default-gw"	= "172.21.10.1"
		}
	}
}
