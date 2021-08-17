locals {
	network_interfaces = var.network_interfaces
	networks = var.networks
	portgroups = var.portgroups
	clusters = var.clusters
	storage = var.storage
	nodes = merge([
		for key,cluster in local.clusters: {
			for node in cluster.nodes: node => key
		}
	]...)
	vsan_disk_groups = merge([
		for key,cluster in local.clusters: {
			for node in cluster.nodes:
				node => local.storage[cluster.storage]
			if (try(local.storage[cluster.storage].cache, false) != false && try(local.storage[cluster.storage].capacity, false) != false)
		}
		if try(cluster.storage, false) != false
	]...)
	local_datastores = merge([
		for key,cluster in local.clusters: {
			for node in cluster.nodes:
				node => local.storage[cluster.storage]
			if (try(local.storage[cluster.storage].cache, false) == false && try(local.storage[cluster.storage].capacity, false) != false)
		}
		if try(cluster.storage, false) != false
	]...)
	compute_clusters = merge([
		for key,cluster in local.clusters: {
			(key) = {
				vsan = (try(local.storage[cluster.storage].cache, false) != false) ? true : false
				vcls = (try(cluster.vcls, "notexist") != "notexist") ? cluster.vcls : true
				nodes = cluster.nodes			
			}
		}
	]...)
}

resource "vsphere_datacenter" "datacenter" {
	name = "lab01"
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
	max_mtu		= 8900
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
	#mtu		= 9000
	ipv4 {
		ip	= "${regex("[0-9]+\\.[0-9]+\\.[0-9]+", local.networks["pg-vmotion"])}.${count.index + 121}"
		netmask	= "255.255.255.0"
		gw	= "${regex("[0-9]+\\.[0-9]+\\.[0-9]+", local.networks["pg-vmotion"])}.254"
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
	#mtu		= 9000
	ipv4 {
		ip	= "${regex("[0-9]+\\.[0-9]+\\.[0-9]+", local.networks["pg-vsan"])}.${count.index + 121}"
		netmask	= "255.255.255.0"
		gw	= "${regex("[0-9]+\\.[0-9]+\\.[0-9]+", local.networks["pg-vsan"])}.254"
	}
	netstack	= "defaultTcpipStack"
	depends_on = [ # ensure that vmk2 is for vsan
		vsphere_vnic.vmk1
	]
}

# mark vmk2 with tag = VSAN
resource "null_resource" "vsan-tag" {
        for_each		= local.vsan_disk_groups
	triggers = {
		host		= each.key
	}
	connection {
		host		= self.triggers.host
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

# mark cache disk as SSD
resource "null_resource" "marked-disk-ssd" {
        for_each		= local.vsan_disk_groups
	triggers = {
		host		= each.key
		cache		= each.value.cache
	}
	connection {
		host		= self.triggers.host
		type		= "ssh"
		user		= "root"
		password	= "VMware1!SDDC"
	}
	provisioner "remote-exec" {
		inline	= [<<-EOT
			## 7.0 ##
			esxcli storage hpp device set -d "${self.triggers.cache}" --mark-device-ssd=true
			esxcli storage hpp device usermarkedssd list
			## 6.7 ##
			#esxcli storage nmp satp rule add -s VMW_SATP_LOCAL -d "${self.triggers.cache}" -o enable_ssd
			#esxcli storage core claiming reclaim -d "${self.triggers.cache}"
			#esxcli storage core device list -d "${self.triggers.cache}" | grep SSD
		EOT
		]
	}
	depends_on = [ # ensure that vmk exists
		vsphere_vnic.vmk2
	]
}

## foreach cluster, create cluster
resource "vsphere_compute_cluster" "cluster" {
	for_each		= local.compute_clusters
	name			= each.key
	datacenter_id		= vsphere_datacenter.datacenter.moid
	drs_enabled		= true
	drs_automation_level	= "partiallyAutomated"
	ha_enabled		= false
	force_evacuate_on_destroy = true
	host_system_ids = [
		for key in each.value.nodes: vsphere_host.host[key].id
	]
	vsan_enabled		= each.value.vsan
	depends_on = [
		null_resource.marked-disk-ssd
	]
}

# claim disks
## need to add logic per cluster
resource "null_resource" "vsan-disk-group" {
	for_each		= local.vsan_disk_groups
	triggers = {
		host		= each.key
		cache		= each.value.cache
		capacity	= each.value.capacity[0]
	}
	connection {
		host		= self.triggers.host
		type		= "ssh"
		user		= "root"
		password	= "VMware1!SDDC"
	}
	provisioner "remote-exec" {
		inline	= [<<-EOT
			esxcli vsan storage add -s "${self.triggers.cache}" -d "${self.triggers.capacity}"
		EOT
		]
	}
	provisioner "remote-exec" {
		when = destroy
		inline	= [<<-EOT
			esxcli vsan storage remove -s "${self.triggers.cache}"
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
	for_each	= local.local_datastores
	name		= "ds-${each.key}"
	host_system_id	= vsphere_host.host[each.key].id
	disks	= [
		each.value.capacity[0]
	]
	depends_on = [
		vsphere_compute_cluster.cluster
	]
}
