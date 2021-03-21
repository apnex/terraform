data "vsphere_network" "vmotion" {
	name		= "pg-vmotion"
	datacenter_id	= data.vsphere_datacenter.datacenter.id
	distributed_virtual_switch_uuid = data.vsphere_distributed_virtual_switch.dvs.id
}

data "vsphere_network" "vsan" {
	name		= "pg-vsan"
	datacenter_id	= data.vsphere_datacenter.datacenter.id
	distributed_virtual_switch_uuid = data.vsphere_distributed_virtual_switch.dvs.id
}

resource "vsphere_vnic" "vmk1" {
	count			= length(var.nodes)
	host			= element(data.vsphere_host.host.*.id, count.index)
	distributed_switch_port	= data.vsphere_distributed_virtual_switch.dvs.id
	distributed_port_group	= data.vsphere_network.vmotion.id
	ipv4 {
		ip	= "172.16.11.${count.index + 111}"
		netmask	= "255.255.255.0"
		gw	= "172.16.11.1"
	}
	netstack	= "vmotion"
}

resource "vsphere_vnic" "vmk2" {
	count			= length(var.nodes)
	host			= element(data.vsphere_host.host.*.id, count.index)
	distributed_switch_port	= data.vsphere_distributed_virtual_switch.dvs.id
	distributed_port_group	= data.vsphere_network.vsan.id
	ipv4 {
		ip	= "172.16.12.${count.index + 111}"
		netmask	= "255.255.255.0"
		gw	= "172.16.12.1"
	}
	netstack	= "defaultTcpipStack"
	depends_on = [ # ensure that vmk2 is for vsan
		vsphere_vnic.vmk1
	]
}
