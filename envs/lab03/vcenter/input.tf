terraform {
	backend "local" {
		path = "./terraform.tfstate"
	}
}

data "terraform_remote_state" "stage0" {
	backend = "local"
	config = {
		path = "../dns/terraform.tfstate"
	}
}

variable "vmw" {
	default = {
		lab_id		= "2",
		vcenter_url	= "http://10.30.0.30:9000/iso/VMware-VCSA-all-7.0.1-17327517.iso"
		not_dry_run	= "true"
	}
}
