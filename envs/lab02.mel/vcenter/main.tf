locals {
	prefix		= "lab0${var.vmw.lab_id}"	
	vcenter_url	= var.vmw.vcenter_url
	not_dry_run	= var.vmw.not_dry_run
	vcenter_file	= "vcenter.iso"
	vcenter_json	= "${path.root}/vcsa.json"
	dns_server	= data.terraform_remote_state.stage0.outputs.dns-service-ip
	gateway		= "172.16.10.1"
	ip		= "172.16.10.120"
	ip_prefix	= "24"
	ntp_server	= "172.16.10.1"
	name		= "vcenter.lab02.mel"
	system_name	= "vcenter.lab02.mel"
	json		= jsonencode({
		"__version": "2.13.0",
		"new_vcsa": {
			"vc": {
				"hostname": "vcenter.lab",
				"username": "administrator@vsphere.local",
				"password": "VMware1!SDDC",
				"deployment_network": "pg-mgmt",
				"datacenter": [
					"mel"
				],
				"datastore": "ds-esx09",
				"target": [
					"cmp",
					"Resources",
					local.prefix
				]
			},
			"appliance": {
				"thin_disk_mode": true,
				"deployment_option": "tiny",
				"name": local.name
			},
			"network": {
				"ip_family": "ipv4",
					"mode": "static",
				"ip": local.ip,
				"dns_servers": [
					local.dns_server
				],
				"prefix": local.ip_prefix,
				"gateway": local.gateway,
				"system_name": local.system_name,
			},
			"os": {
				"password": "VMware1!SDDC",
				"ntp_servers": local.ntp_server,
				"ssh_enable": true
			},
			"sso": {
				"password": "VMware1!SDDC",
				"domain_name": "vsphere.local"
			}
		},
		"ceip": {
			"settings": {
				"ceip_enabled": false
			}
		}
	})
}

resource "local_file" "vcsa-json" {
	content		= local.json
	filename	= local.vcenter_json
}

# install vcenter
module "vcenter" {
	source			= "../../../modules/vcenter"
	prefix			= local.prefix
	vcenter_url		= local.vcenter_url
	vcenter_file		= local.vcenter_file
	vcenter_json		= local.vcenter_json
	not_dry_run		= local.not_dry_run
	depends_on = [
		local_file.vcsa-json
	]
}
