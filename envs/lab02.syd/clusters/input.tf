terraform {
	backend "local" {
		path = "./terraform.tfstate"
	}
}

provider "vsphere" {
	vsphere_server		= "vcenter.lab02.syd"
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
				"esx21.lab02.syd",
				"esx22.lab02.syd",
				"esx23.lab02.syd"
			]
		}
		mgmt	= {
			storage	= "local"
			nodes	= [
				"esx24.lab02.syd"
			]
		}
	}
}
variable "networks" {
	default = {
		"pg-mgmt"	= "10.30.0.0/24",
		"pg-vmotion"	= "10.30.2.0/24",
		"pg-vsan"	= "10.30.3.0/24"
	}
}
variable "portgroups" {
	default = {
		"pg-mgmt"	= 0,
		"pg-vmotion"	= 302,
		"pg-vsan"	= 303
	}
}
