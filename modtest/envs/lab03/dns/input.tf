terraform {
	backend "local" {
		path = "./terraform.tfstate"
	}
}

data "terraform_remote_state" "stage0" {
	backend = "local"
	config = {
		path = "../terraform.tfstate"
	}
}

locals {
	master_ip	= data.terraform_remote_state.stage0.outputs.controller_ip
	manifest	= "lab03-dns.yaml"
	data		= jsondecode(file("${path.module}/data.json"))
}

variable "dns_key" {
	default = "dnsctl."
}

variable "dns_key_secret" {
	#echo -n 'VMware1!' | base64
	default = "Vk13YXJlMSE="
}
