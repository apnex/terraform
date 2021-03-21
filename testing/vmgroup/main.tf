data "vsphere_datacenter" "datacenter" {
	name          = "lab01"
}

data "vsphere_compute_cluster" "cluster" {
	name          = "cmp"
	datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_network" "network" {
	name          = "pg-mgmt"
	datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_datastore" "datastore" {
	name          = "vsanDatastore"
	datacenter_id = data.vsphere_datacenter.datacenter.id
}

# pull file
resource "null_resource" "labopsfile" {
	provisioner "local-exec" {
		interpreter = ["/bin/bash" ,"-c"]
		command = <<-EOT
			if [[ -f "labops.centos.stage1.iso" ]]; then
				echo "file EXISTS"
			else
				wget http://labops.sh/library/labops.centos.stage1.iso
			fi
		EOT
	}
	provisioner "local-exec" {
		when = destroy
		interpreter = ["/bin/bash" ,"-c"]
		command = <<-EOT
			rm -rf labops.centos.stage1.iso
		EOT
	}
}

# upload file
resource "vsphere_file" "labops-upload" {
	datacenter       = "lab01"
	datastore        = "vsanDatastore"
	source_file      = "./labops.centos.stage1.iso"
	destination_file = "iso/labops.centos.stage1.iso"
	depends_on = [
		null_resource.labopsfile
	]
}

resource "vsphere_virtual_machine" "vm" {
	for_each			= var.nodes
	name				= each.key
	resource_pool_id		= data.vsphere_compute_cluster.cluster.resource_pool_id
	datastore_id			= data.vsphere_datastore.datastore.id
	wait_for_guest_net_timeout	= 0
	wait_for_guest_ip_timeout	= 0

	num_cores_per_socket	= 2
	num_cpus		= 2
	memory			= 4096
	guest_id		= "centos7_64Guest"
	nested_hv_enabled	= true

	lifecycle {
		ignore_changes = [
			cdrom
		]
	}
	cdrom {
		datastore_id = data.vsphere_datastore.datastore.id
		path         = "iso/labops.centos.stage1.iso"
	}

	network_interface {
		network_id = data.vsphere_network.network.id
	}

	disk {
		label = "disk0"
		size  = 32
	}

	depends_on = [
		vsphere_file.labops-upload
	]
}
