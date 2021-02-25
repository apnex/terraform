data "vsphere_datacenter" "datacenter" {
	name = "lab01"
}

data "vsphere_host" "host" {
	name          = "esx11.lab01"
	datacenter_id = data.vsphere_datacenter.datacenter.id
}

resource "vsphere_compute_cluster" "cmp" {
	# imported arguments
}

resource "vsphere_vnic" "vmk0" {
	# imported arguments
}

resource "vsphere_host_virtual_switch" "vswitch" {
	# imported arguments
}

resource "vsphere_distributed_virtual_switch" "d1" {
  name          = "dc_DVPG0"
  datacenter_id = data.vsphere_datacenter.dc.id
  host {
    host_system_id = data.vsphere_host.h1.id
    devices        = ["vnic3"]
  }
}

resource "vsphere_distributed_port_group" "p1" {
  name                            = "test-pg"
  vlan_id                         = 1234
  distributed_virtual_switch_uuid = vsphere_distributed_virtual_switch.d1.id
}

resource "vsphere_vnic" "v1" {
  host                    = data.vsphere_host.h1.id
  distributed_switch_port = vsphere_distributed_virtual_switch.d1.id
  distributed_port_group  = vsphere_distributed_port_group.p1.id
  ipv4 {
    dhcp = true
  }
  netstack = "vmotion"
}
