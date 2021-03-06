provider "vsphere" {
	vsphere_server		= "vcenter.lab02.mel"
	user			= "administrator@vsphere.local"
	password		= "VMware1!SDDC"
	allow_unverified_ssl	= true
}


## separate locals to an input
## look at definition of switching and storage
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
			storage	= {
				vsan = {
					cache	= "mpx.vmhba0:C0:T1:L0"
					storage	= [
						"mpx.vmhba0:C0:T2:L0"
					]
				}
			}
			nodes	= [
				"esx21.lab02.mel",
				"esx22.lab02.mel",
				"esx23.lab02.mel"
			]
		}
		mgmt	= {
			storage	= {
				local = {
					disks = [
						"mpx.vmhba0:C0:T2:L0"
					]
				}
			}
			nodes	= [ # "ds-<name"
				"esx24.lab02.mel"
			]
		}
	}
	nodes = merge([
		for key,cluster in local.clusters: {
			for node in cluster.nodes: node => key
		}
	]...)
}

resource "vsphere_datacenter" "datacenter" {
	name = "lab02"
}

# foreach host, get thumbprint
data "vsphere_host_thumbprint" "thumbprint" {
	for_each	= local.nodes
	address		= each.key
	insecure	= true
}

# foreach host, join to datacenter
resource "vsphere_host" "host" {
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

# mark vmk2 wirh tag = VSAN
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

# mark mpx.vmhba0:C0:T1:L0 as SSD
resource "null_resource" "marked-disk-ssd" {
	#count			= length(local.nodes)
	count			= length(local.clusters.cmp.nodes)
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
			esxcli storage hpp device set -d mpx.vmhba0:C0:T1:L0 --mark-device-ssd=true
			esxcli storage hpp device usermarkedssd list
		EOT
		]
	}
	depends_on = [ # ensure that vmk exists
		vsphere_vnic.vmk2
	]
}

## foreach cluster, create cluster
resource "vsphere_compute_cluster" "cluster" {
	for_each		= local.clusters
	name			= each.key
	datacenter_id		= vsphere_datacenter.datacenter.moid
	drs_enabled		= true
	drs_automation_level	= "partiallyAutomated"
	ha_enabled		= false
	force_evacuate_on_destroy = true
	host_system_ids = [
		for key in each.value.nodes: vsphere_host.host[key].id
	]
	vsan_enabled		= try(each.value.vsan, false)
	#vsan_disk_group {
	#	cache		= "mpx.vmhba0:C0:T1:L0"
	#	storage		= [ "mpx.vmhba0:C0:T2:L0" ]
	#}
	depends_on = [
		null_resource.marked-disk-ssd
	]
}

# claim disks
## need to add logic per cluster
resource "null_resource" "vsan-disk-group" {
	#count			= length(local.nodes)
	count			= length(local.clusters.cmp.nodes)
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
			esxcli vsan storage add -s mpx.vmhba0:C0:T1:L0 -d mpx.vmhba0:C0:T2:L0
		EOT
		]
	}
	provisioner "remote-exec" {
		when = destroy
		inline	= [<<-EOT
			esxcli vsan storage remove -s mpx.vmhba0:C0:T1:L0
			esxcli vsan storage list
		EOT
		]
	}
	depends_on = [
		vsphere_compute_cluster.cluster
	]
}

# create local datastore
resource "vsphere_vmfs_datastore" "datastore" {
	name		= "ds-esx24"
	host_system_id	= vsphere_host.host["esx24.lab02.mel"].id
	disks	= [
		"mpx.vmhba0:C0:T2:L0"
	]
	depends_on = [
		#vsphere_host.host["esx24.lab02.mel"].id
		vsphere_compute_cluster.cluster
	]
}

#data "vsphere_vmfs_disks" "available" {
#	host_system_id	= vsphere_host.host["esx24.lab02.mel"].id
#	rescan         = true
#	depends_on = [
#		vsphere_host.host["esx24.lab02.mel"]
#	]
#}
