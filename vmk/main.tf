provider "vsphere" {
	version			= "~> 1.23.0" # errors with > 1.24
	vsphere_server		= "vcenter.lab01"
	user			= "administrator@vsphere.local"
	password		= "VMware1!SDDC"
	allow_unverified_ssl	= true
}

variable "nodes" {
	default = [
		"esx11.lab01",
		"esx12.lab01",
		"esx13.lab01",
	]
}

variable "network_interfaces" {
	default = [
		"vmnic1"
	]
}

data "vsphere_datacenter" "datacenter" {
	name = "lab01"
}

data "vsphere_host" "host" {
	for_each	= toset(var.nodes)
	name		= each.key
	datacenter_id   = data.vsphere_datacenter.datacenter.id
}

resource "vsphere_distributed_virtual_switch" "dvs" {
	name		= "aterraform-test-dvs"
	datacenter_id	= data.vsphere_datacenter.datacenter.id
	uplinks		= ["uplink1", "uplink2"]
	active_uplinks	= ["uplink1"]

	host {
		host_system_id = data.vsphere_host.host["esx11.lab01"].id
		devices        = var.network_interfaces
	}
	host {
		host_system_id = data.vsphere_host.host["esx12.lab01"].id
		devices        = var.network_interfaces
	}
	host {
		host_system_id = data.vsphere_host.host["esx13.lab01"].id
		devices        = var.network_interfaces
	}
}
[root@docker01 vds]# cd ../vmk/
[root@docker01 vmk]# ll
total 12
-rw-r--r-- 1 root root 366 Nov 11 22:38 data.tf
-rw-r--r-- 1 root root 785 Nov 11 22:35 main.tf
-rw-r--r-- 1 root root 430 Nov 11 22:35 vars.tf
[root@docker01 vmk]# more main.tf 
resource "vsphere_distributed_port_group" "pg-rubrik-data" {
  name                            = "Rubrik_Data"
  vlan_id                         = 150
  distributed_virtual_switch_uuid = "${data.vsphere_distributed_virtual_switch.dvs.id}"
  active_uplinks                  = ["uplink1", "uplink2"]
  standby_uplinks                 = []
}
resource "vsphere_vnic" "v1" {
  count = "${length(var.esxi_hosts)}"
  host = "${element(data.vsphere_host.host.*.id, count.index)}"
  distributed_switch_port = data.vsphere_distributed_virtual_switch.dvs.id
  distributed_port_group  = vsphere_distributed_port_group.pg-rubrik-data.id
  ipv4 {
    ip = "192.168.150.${count.index + 41}"
    netmask = "255.255.255.0"
    gw = "192.168.150.1"
  }
  netstack                = "defaultTcpipStack"
}
