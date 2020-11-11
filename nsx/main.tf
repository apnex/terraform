provider "vsphere" {
	version			= "~> 1.23.0" # errors with > 1.24
	vsphere_server		= "vcenter.lab"
	user			= "administrator@vsphere.local"
	password		= "VMware1!"
	allow_unverified_ssl	= true
}

module "nsx-manager" {
	### module source
	source			= "github.com/apnex/module-nsx-manager"

	### vsphere variable
	datacenter		= "mel"
	cluster			= "cmp"
	datastore		= "ds-esx09"
	host			= "sddc.lab"
	dvs			= "fabric"
	network			= "pg-mgmt"

	## nsx variables
	remote_ovf_url		= "http://172.16.10.53:9000/iso/nsx-unified-appliance-3.1.0.0.0.17107171.ova"
	nsx_hostname		= "nsxm.lab01"
	nsx_role		= "NSX Manager"
	nsx_ip_0		= "172.16.10.117"
	nsx_netmask_0		= "255.255.255.0"
	nsx_gateway_0		= "172.16.10.1"
	nsx_dns1_0		= "172.16.10.1"
	nsx_ntp_0		= "172.16.10.1"
	nsx_passwd_0		= "VMware1!"
	nsx_cli_passwd_0	= "VMware1!"
	nsx_cli_audit_passwd_0	= "VMware1!"
	nsx_isSSHEnabled	= "True"
	nsx_allowSSHRootLogin	= "True"
}
