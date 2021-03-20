variable "vmw" {
	default = {
		lab_id		= "2",
		vcenter_url	= "http://10.30.0.30:9000/iso/VMware-VCSA-all-7.0.1-17327517.iso"
		vcenter_file	= "vcenter.iso"
		vcenter_json	= "vcsa.json"
		not_dry_run	= "true"
	}
}
