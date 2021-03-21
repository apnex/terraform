locals {
	prefix			= var.prefix
	bootfile_url		= var.bootfile_url
	bootfile_name		= "${local.prefix}-esx.iso"
	bootfile_path		= join("/", [abspath(path.root), "state/${local.bootfile_name}"])
	esx_name		= var.esx_name
	esx_id			= var.esx_id
	esx_network		= var.esx_network
	esx_datastore		= var.esx_datastore
	datacenter		= var.datacenter
}

### inherit from parent?
data "vsphere_datacenter" "datacenter" {
	name			= local.datacenter
}

data "vsphere_network" "network" {
	name			= local.esx_network
	datacenter_id		= data.vsphere_datacenter.datacenter.id
}

data "vsphere_datastore" "datastore" {
	name			= local.esx_datastore
	datacenter_id		= data.vsphere_datacenter.datacenter.id
}

data "vsphere_vapp_container" "lab" {
	name			= local.prefix
	datacenter_id		= data.vsphere_datacenter.datacenter.id
}
### inherit from parent???

# pull file - turn into docker resource?
resource "null_resource" "pull-file" {
	triggers = {
		file_name	= local.bootfile_path
		file_url	= local.bootfile_url
		exists		= fileexists(local.bootfile_path)
	}
	provisioner "local-exec" {
		interpreter = ["/bin/bash" ,"-c"]
		command = <<-EOT
			if [[ -f "${self.triggers.file_name}" ]]; then
				echo "file EXISTS ${self.triggers.file_name}"
			else
				echo "file NOT EXISTS ${self.triggers.file_name}"
				curl -Lo "${self.triggers.file_name}" "${self.triggers.file_url}"
			fi
		EOT
	}
	provisioner "local-exec" {
		when    = destroy
		command = <<-EOT
			if [[ -f "${self.triggers.file_name}" ]]; then
				rm "${self.triggers.file_name}"
			fi
		EOT
	}
}

# upload file
resource "vsphere_file" "push-file" {
	datacenter       = local.datacenter
	datastore        = local.esx_datastore
	source_file      = local.bootfile_path
	destination_file = "iso/${local.bootfile_name}"
	depends_on = [
		null_resource.pull-file
	]
}

resource "vsphere_virtual_machine" "vm-esx" {
	name				= local.esx_name
	resource_pool_id		= data.vsphere_vapp_container.lab.id
	datastore_id			= data.vsphere_datastore.datastore.id
	#wait_for_guest_net_timeout	= 40 # minutes
	wait_for_guest_net_timeout	= 0
	wait_for_guest_ip_timeout	= 0
	depends_on = [
		vsphere_file.push-file
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
		path			= "iso/${local.bootfile_name}"
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
		mac_address		= "00:de:ad:be:${local.esx_id}:01"
		network_id		= data.vsphere_network.network.id
	}
	network_interface {
		use_static_mac		= true
		mac_address		= "00:de:ad:be:${local.esx_id}:02"
		network_id		= data.vsphere_network.network.id
	}
}
