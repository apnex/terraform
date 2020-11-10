data "vsphere_datacenter" "datacenter" {
	name          = var.datacenter
}

data "vsphere_datastore" "datastore" {
	name          = var.datastore
	datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_resource_pool" "pool" {
	name          = var.pool
	datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_host" "host" {
	name          = var.host
	datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_distributed_virtual_switch" "dvs" {
	name          = var.dvs
	datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_network" "network" {
	name          = var.network
	datacenter_id = data.vsphere_datacenter.datacenter.id
	distributed_virtual_switch_uuid = data.vsphere_distributed_virtual_switch.dvs.id
}

resource "vsphere_virtual_machine" "nsx-manager" {
	name                       = "nsx-manager"
	datacenter_id              = data.vsphere_datacenter.datacenter.id
	resource_pool_id           = data.vsphere_resource_pool.pool.id
	datastore_id               = data.vsphere_datastore.datastore.id
	host_system_id             = data.vsphere_host.host.id
	wait_for_guest_net_timeout = 0
	wait_for_guest_ip_timeout  = 0

	ovf_deploy {
		local_ovf_path		= "/home/terraform/nsx-unified-appliance-3.1.0.0.0.17107171.ova"
		disk_provisioning	= "thin"
		ovf_network_map		= {
			"Network 1" = data.vsphere_network.network.id
		}
	}
	vapp {
		properties = {
			"nsx_hostname"			= "nsxm.lab01"
			"nsx_role"			= "NSX Manager"
			"nsx_ip_0"			= "172.16.10.117"
			"nsx_netmask_0"			= "255.255.255.0"
			"nsx_gateway_0"			= "172.16.10.1"
			"nsx_dns1_0"			= "172.16.10.1"
			"nsx_ntp_0"			= "172.16.10.1"
			"nsx_passwd_0"			= "VMware1!SDDC"
			"nsx_cli_passwd_0"		= "VMware1!SDDC"
			"nsx_cli_audit_passwd_0"	= "VMware1!SDDC"
			"nsx_isSSHEnabled"		= "True"
			"nsx_allowSSHRootLogin"		= "True"
		}
	}
}
