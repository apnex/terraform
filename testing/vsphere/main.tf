data "vsphere_datacenter" "datacenter" {
	name			= "core"
}

data "vsphere_compute_cluster" "cluster" {
	name			= "core"
	datacenter_id		= data.vsphere_datacenter.datacenter.id
}

data "vsphere_network" "network" {
	name			= var.vmw.network
	datacenter_id		= data.vsphere_datacenter.datacenter.id
}

data "vsphere_datastore" "datastore" {
	name			= var.vmw.datastore
	datacenter_id		= data.vsphere_datacenter.datacenter.id
}

## DRS required on cluster for this to function
resource "vsphere_vapp_container" "lab" {
	name			= "lab01"
	parent_resource_pool_id	= data.vsphere_compute_cluster.cluster.resource_pool_id
}

# pull file - turn into docker resource
resource "null_resource" "pull-file-esx" {
	triggers = {
		always_run = timestamp()
	}
	provisioner "local-exec" {
		interpreter = ["/bin/bash" ,"-c"]
		command = <<-EOT
			if [[ -f "esx.iso" ]]; then
				echo "file EXISTS"
			else
				wget http://esx.apnex.io/esx.iso
			fi
		EOT
	}
	provisioner "local-exec" {
		when    = destroy
		command = "rm -rf esx.iso"
	}
}

# upload file
resource "vsphere_file" "push-file-esx" {
	datacenter       = "core"
	datastore        = var.vmw.datastore
	source_file      = "./esx.iso"
	destination_file = "iso/esx.iso"
	depends_on = [
		null_resource.pull-file-esx
	]
}

resource "vsphere_virtual_machine" "vm-esx" {
	count				= length(var.vmw.nodes)
	name				= var.vmw.nodes[count.index].name
	resource_pool_id		= vsphere_vapp_container.lab.id
	datastore_id			= data.vsphere_datastore.datastore.id
	wait_for_guest_net_timeout	= 0
	wait_for_guest_ip_timeout	= 0
	depends_on = [
		vsphere_file.push-file-esx
	]
	lifecycle {
		ignore_changes = [
			cdrom
		]
	}

	# resources
	guest_id			= "vmkernel7Guest"
	nested_hv_enabled		= true
	num_cores_per_socket		= 4
	num_cpus			= 4
	memory				= 8192
	memory_reservation		= 8192

	# hardware
	cdrom {
		datastore_id		= data.vsphere_datastore.datastore.id
		path			= "iso/esx.iso"
	}
	disk {
		label			= "disk0"
		unit_number		= 0 
		thin_provisioned	= true
		size			= 8
	}
	disk {
		label			= "disk1"
		unit_number		= 1
		thin_provisioned	= true
		size			= 20
	}
	disk {
		label			= "disk2"
		unit_number		= 2
		thin_provisioned	= true
		size			= 200
	}
	network_interface {
		use_static_mac		= true
		mac_address		= "00:de:ad:be:2${count.index}:01"
		network_id		= data.vsphere_network.network.id
	}
	network_interface {
		use_static_mac		= true
		mac_address		= "00:de:ad:be:2${count.index}:02"
		network_id		= data.vsphere_network.network.id
	}
}
