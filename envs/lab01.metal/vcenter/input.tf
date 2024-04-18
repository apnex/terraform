terraform {
	backend "local" {
		path = "./terraform.tfstate"
	}
}

variable "vmw" {
	default = {
		lab_id		= "1",
		vcenter_url	= "http://iso.apnex.io/VMware-VCSA-all-7.0.3-18778458.iso"
		dns_server	= "136.144.62.202"
		not_dry_run	= "false"
	}
}
