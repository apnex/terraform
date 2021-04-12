provider "vsphere" {
	vsphere_server		= "vcenter.lab02.mel"
	user			= "administrator@vsphere.local"
	password		= "VMware1!SDDC"
	allow_unverified_ssl	= true
}

locals {
	network_interfaces = [
		"vmnic1"
	]
	portgroups = {
		"pg-mgmt"	= 0,
		"pg-vmotion"	= 11,
		"pg-vsan"	= 12
	}
	clusters = {
		cmp	= {
			vsan	= true
			nodes	= [
				"esx21.lab02.mel",
				"esx22.lab02.mel",
				"esx23.lab02.mel"
			]
		}
		mgmt	= {
			nodes	= [
				"esx24.lab02.mel"
			]
		}
	}
	nodes = merge([
		for key,cluster in local.clusters: {
			#for node in cluster.nodes: node => cluster.name
			for node in cluster.nodes: node => key
		}
	]...)
}

resource "vsphere_datacenter" "datacenter" {
	name = "lab02"
}

# foreach host, get thumbprint
data "vsphere_host_thumbprint" "thumbprint" {
	#for_each        = toset(local.nodes)
	for_each	= local.nodes
	address		= each.key
	insecure	= true
}

# foreach host, join to datacenter
resource "vsphere_host" "host" {
	#for_each	= toset(local.nodes)
	for_each	= local.nodes
	hostname	= each.key
	username	= "root"
	password	= "VMware1!SDDC"
	thumbprint	= data.vsphere_host_thumbprint.thumbprint[each.key].id
	datacenter	= vsphere_datacenter.datacenter.moid
	cluster_managed = true
}

# create switch
resource "vsphere_distributed_virtual_switch" "dvs" {
	name		= "fabric"
	datacenter_id	= vsphere_datacenter.datacenter.moid
	uplinks		= ["uplink1","uplink2"]
	active_uplinks	= ["uplink1","uplink2"]
	standby_uplinks	= []
	max_mtu		= 9000
	dynamic "host" {
		#for_each = toset(local.nodes)
		for_each = local.nodes
		content {
			host_system_id = vsphere_host.host[host.key].id
			devices        = local.network_interfaces
		}
	}
}

# create portgroups
resource "vsphere_distributed_port_group" "pgs" {
	for_each			= local.portgroups
	name                            = each.key
	allow_forged_transmits		= true
	allow_mac_changes		= true
	allow_promiscuous		= false
	distributed_virtual_switch_uuid	= vsphere_distributed_virtual_switch.dvs.id
	vlan_id				= each.value
}

resource "vsphere_vnic" "vmk1" {
	count			= length(local.nodes)
	host			= values(vsphere_host.host)[count.index].id
	distributed_switch_port	= vsphere_distributed_virtual_switch.dvs.id
	distributed_port_group	= values(vsphere_distributed_port_group.pgs)[1].id
	lifecycle {
		ignore_changes = [
			ipv6
		]
	}
	mtu		= 9000
	ipv4 {
		ip	= "172.16.11.${count.index + 121}"
		netmask	= "255.255.255.0"
		gw	= "172.16.11.1"
	}
	netstack	= "vmotion"
}

resource "vsphere_vnic" "vmk2" {
	count			= length(local.nodes)
	host			= values(vsphere_host.host)[count.index].id
	distributed_switch_port	= vsphere_distributed_virtual_switch.dvs.id
	distributed_port_group	= values(vsphere_distributed_port_group.pgs)[2].id
	lifecycle {
		ignore_changes = [
			ipv6
		]
	}
	mtu		= 9000
	ipv4 {
		ip	= "172.16.12.${count.index + 121}"
		netmask	= "255.255.255.0"
		gw	= "172.16.12.1"
	}
	netstack	= "defaultTcpipStack"
	depends_on = [ # ensure that vmk2 is for vsan
		vsphere_vnic.vmk1
	]
}

# vsan-tag
resource "null_resource" "vsan-tag" {
	count			= length(local.nodes)
	triggers = {
		run_always	= timestamp()
	}
	connection {
		host		= "172.16.10.${count.index + 121}"
		type		= "ssh"
		user		= "root"
		password	= "VMware1!SDDC"
	}
	provisioner "remote-exec" {
		inline	= [<<-EOT
			esxcli network ip interface tag add -i vmk2 -t VSAN
			esxcli network ip interface tag get -i vmk2
		EOT
		]
	}
	provisioner "remote-exec" {
		when = destroy
		inline	= [<<-EOT
			esxcli network ip interface tag remove -i vmk2 -t VSAN
			esxcli network ip interface tag get -i vmk2
		EOT
		]
	}
	depends_on = [ # ensure that vmk exists
		vsphere_vnic.vmk2
	]
}
