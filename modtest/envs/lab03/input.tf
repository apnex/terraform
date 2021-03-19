provider "vsphere" {
	version			= "> 1.23"
	vsphere_server		= "vcenter.core.syd"
	user			= "administrator@vsphere.local"
	password		= "VMware1!SDDC"
	allow_unverified_ssl	= true
}

variable "vmw" {
	default = {
		lab_id = 3
		datacenter = "core"
		cluster = "cmp"
		controller = {
			name = "router"
			network = "pg-mgmt"
			datastore = "ds-esx04"
			bootfile_url = "http://labops.sh/library/labops.centos.stage2.iso"
			bootfile_name = "labops.centos.stage2.iso"
		}
	}
}
