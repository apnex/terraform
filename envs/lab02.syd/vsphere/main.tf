locals {
	prefix		= "lab0${var.vmw.lab_id}"	
	#dns_server	= data.terraform_remote_state.stage0.outputs.dns-service-ip
	gateway		= "10.30.0.254"
	ip		= "10.30.0.120"
	ip_prefix	= "24"
	ntp_server	= "10.30.0.30"
	name		= "vcenter.lab02.syd"
	system_name	= "vcenter.lab02.syd"
}

# install vcenter
module "vsphere" {
	source		= "../../../modules/vsphere"
	count		= 4

	prefix		= local.prefix
	esx_id		= "${var.vmw.lab_id}${count.index + 1}"
	esx_name	= "esx${var.vmw.lab_id}${count.index + 1}"
	esx_network	= "pg-trunk"
	esx_datastore	= "ds-esx09"
	datacenter	= "mel"
	bootfile_url	= "http://esx.apnex.io/esx.iso"
}
