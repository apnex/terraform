variable "avi_username" {
	default = "admin"
}
variable "avi_password" {
	default = "VMware1!SDDC"
}
variable "avi_controller" {
	default = "avic.lab01.one"
}
variable "avi_version" {
	default = "20.1.5"
}
variable "tenant" {
	default = "admin"
}
variable "cloud_name" {
	default = "tf_vmware_cloud"
}
variable "vcenter_license_tier" {
	default = "ENTERPRISE"
}
variable "vcenter_license_type" {
	default = "LIC_CORES"
}
variable "vcenter_configuration" {
	default = {
		username		= "administrator@vsphere.local"
		password		= "VMware1!SDDC"
		vcenter_url		= "vcenter.lab01.one"
		datacenter		= "lab01"
		management_network	= "pg-mgmt"
		privilege		= "WRITE_ACCESS"
	}
}
