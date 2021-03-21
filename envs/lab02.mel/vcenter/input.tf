terraform {
	backend "local" {
		path = "./terraform.tfstate"
	}
}

data "terraform_remote_state" "stage0" {
	backend = "local"
	config = {
		path = "../services/terraform.tfstate"
	}
}

variable "vmw" {
	default = {
		lab_id		= "2",
		vcenter_url	= "http://172.16.100.52:9000/iso/VMware-VCSA-all-7.0.2-17694817.iso"
		not_dry_run	= "true"
	}
}
