terraform {
	backend "local" {
		path = "./terraform.tfstate"
	}
}

provider "vsphere" {
	vsphere_server		= "vcenter.lab01.one"
	user			= "administrator@vsphere.local"
	password		= "VMware1!SDDC"
	allow_unverified_ssl	= true
}

# all disks in a cluster must be the same
# if cache disk present, create a vsan_disk_group on host
variable "storage" {
	default = {
		vsan = {
			cache = "mpx.vmhba0:C0:T1:L0"
			capacity = [
				"mpx.vmhba0:C0:T2:L0"
			]
		}
		local = {
			capacity = [
				"mpx.vmhba0:C0:T2:L0"
			]
		}
	}
}
variable "clusters" {
	default = {
		cmp	= {
			storage	= "vsan"
			nodes	= [
				"esx12.lab01.one",
				"esx13.lab01.one",
				"esx14.lab01.one"
			]
			vcls	= true
		}
		edge	= {
			storage	= "local"
			nodes	= [
				"esx15.lab01.one"
			]
			vcls	= true
		}
	}
}
variable "network_interfaces" {
	default = [
		"vmnic1",
		"vmnic2"
	]
}
variable "networks" {
	default = {
		"pg-mgmt"	= "172.16.10.0/24",
		"pg-vmotion"	= "172.16.11.0/24",
		"pg-vsan"	= "172.16.12.0/24"
	}
}
variable "portgroups" {
	default = {
		"pg-mgmt"	= 0,
		"pg-vmotion"	= 11,
		"pg-vsan"	= 12
	}
}
