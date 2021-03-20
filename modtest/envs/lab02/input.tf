terraform {
	required_providers {
		vsphere = ">= 1.23.0"
	}
}
provider "vsphere" {
	vsphere_server		= "vcenter.core.syd"
	user			= "administrator@vsphere.local"
	password		= "VMware1!SDDC"
	allow_unverified_ssl	= true
}

variable "vmw" {
	default = {
		lab_id = 2
		datacenter = "core"
		cluster = "cmp"
		controller = {
			name = "router"
			network = "pg-mgmt"
			datastore = "ds-esx04"
			bootfile_url = "http://labops.sh/library/labops.centos.stage2.iso"
			bootfile_name = "labops.centos.stage2.iso"
			private_key = "lab02.key"
			public_key = "lab02.key.pub"
		}
	}
}
