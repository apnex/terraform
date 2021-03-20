locals {
	prefix			= "lab0${var.vmw.lab_id}"	
	vcenter_url		= var.vmw.vcenter_url
	vcenter_file		= var.vmw.vcenter_file
	vcenter_json		= var.vmw.vcenter_json
	not_dry_run		= var.vmw.not_dry_run
}

# install vcenter
module "vcenter" {
	source			= "../../../modules/vcenter"
	prefix			= local.prefix
	vcenter_url		= local.vcenter_url
	vcenter_file		= local.vcenter_file
	vcenter_json		= local.vcenter_json
	not_dry_run		= local.not_dry_run
}
