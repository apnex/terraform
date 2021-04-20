locals {
	network_interfaces = [
		"vmnic1"
	]
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
			if try(local.storage[cluster.storage].cache, false) != false
		}
	]...)
	local_datastores = merge([
		for key,cluster in local.clusters: {
			for node in cluster.nodes:
				node => local.storage[cluster.storage]
			if try(local.storage[cluster.storage].cache, false) == false
		}
	]...)
}
