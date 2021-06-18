terraform {
	backend "local" {
		path = "./terraform.tfstate"
	}
}

#data "terraform_remote_state" "stage0" {
#	backend = "local"
#	config = {
#		path = "../services/terraform.tfstate"
#	}
#}

variable "vmw" {
	default = {
		lab_id		= "1",
		vcenter_url	= "http://172.16.10.1:9000/iso/VMware-VCSA-all-7.0.2-17958471.iso"
		dns_server	= "172.16.10.1"
		#dns_server	= data.terraform_remote_state.stage0.outputs.dns-service-ip
		not_dry_run	= "true"
	}
}
