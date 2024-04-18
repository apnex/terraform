locals {
	prefix		= "lab0${var.vmw.lab_id}"	
	vcenter_url	= var.vmw.vcenter_url
	not_dry_run	= var.vmw.not_dry_run
	vcenter_file	= "vcenter.iso"
	vcenter_json	= "${path.root}/vcsa.json"
	dns_server	= var.vmw.dns_server
	## use dns_server to resolve esx fqdn
	gateway		= "136.144.62.201"
	ip		= "136.144.62.203"
	ip_prefix	= "29"
	ntp_server	= "136.144.62.202"
	name		= "vcenter.lab01.metal"
	system_name	= "vcenter.lab01.metal"
	json		= jsonencode({
		"__version": "2.13.0",
		"new_vcsa": {
			"esxi": {
				"hostname": "136.144.62.210",
				"username": "root",
				"password": "Y3)G9fJh;a",
				"deployment_network": "external",
				"datastore": "datastore1"
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
