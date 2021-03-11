locals {
	lab			= "lab0${var.vmw.lab_id}"	
}

data "vsphere_datacenter" "datacenter" {
	name			= "core"
}

data "vsphere_compute_cluster" "cluster" {
	name			= "cmp"
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

resource "vsphere_vapp_container" "lab" {
	name			= local.lab
	parent_resource_pool_id	= data.vsphere_compute_cluster.cluster.resource_pool_id
	lifecycle {
		ignore_changes = [
			parent_folder_id
		]
	}
}

# pull file - turn into docker resource?
resource "null_resource" "pull-file" {
	triggers = {
		#always_run	= timestamp()
		#filexist	= fileexists("./${local.lab}-${var.vmw.bootfile_name}") ? filemd5("./${local.lab}-${var.vmw.bootfile_name}") : ""
		exists		= fileexists("${path.module}/${local.lab}-${var.vmw.bootfile_name}")
		pullfilename	= "${path.module}/${local.lab}-${var.vmw.bootfile_name}"
		pullfileurl	= var.vmw.bootfile_url
		lab		= local.lab
	}
	provisioner "local-exec" {
		interpreter = ["/bin/bash" ,"-c"]
		command = <<-EOF
			if [[ -f "${self.triggers.pullfilename}" ]]; then
				echo "file EXISTS ${self.triggers.pullfilename}"
			else
				echo "file NOT EXISTS ${self.triggers.pullfilename}"
				curl -Lo "${self.triggers.pullfilename}" "${self.triggers.pullfileurl}"
			fi
		EOF
	}
	provisioner "local-exec" {
		when    = destroy
		command = <<-EOF
			if [[ -f "${self.triggers.pullfilename}" ]]; then
				rm "${self.triggers.pullfilename}"
			fi
		EOF
	}
}

# upload file
resource "vsphere_file" "push-file" {
	datacenter       = "core"
	datastore        = var.vmw.datastore
	source_file      = "./${local.lab}-${var.vmw.bootfile_name}"
	destination_file = "iso/${local.lab}-${var.vmw.bootfile_name}"
	depends_on = [
		null_resource.pull-file
	]
}

resource "vsphere_virtual_machine" "vm" {
	name				= "${var.vmw.controller.name}.${local.lab}"
	resource_pool_id		= vsphere_vapp_container.lab.id
	datastore_id			= data.vsphere_datastore.datastore.id
	wait_for_guest_net_timeout	= 20 # minutes
	depends_on = [
		vsphere_file.push-file
	]
	lifecycle {
		ignore_changes = [
			cdrom
		]
	}

	# connection
	connection {
		host		= self.default_ip_address
		type		= "ssh"
		user		= "root"
		password	= "VMware1!"
	}
	provisioner "remote-exec" {
		inline = [<<-EOF
			while [ ! -f /root/startup.done ]; do
				sleep 3;
				echo "Waiting for startup scripts.. "
			done
			hostnamectl set-hostname router
			docker version
			docker ps
		EOF
		]
	}

	# resources
	guest_id			= "centos7_64Guest"
	nested_hv_enabled		= true
	num_cores_per_socket		= 2
	num_cpus			= 2
	memory				= 4096

	# hardware
	cdrom {
		datastore_id		= data.vsphere_datastore.datastore.id
		path			= "iso/${local.lab}-${var.vmw.bootfile_name}"
	}
	disk {
		label			= "disk0"
		unit_number		= 0 
		thin_provisioned	= true
		size			= 32
	}
	network_interface {
		network_id		= data.vsphere_network.network.id
	}
	network_interface {
		network_id		= data.vsphere_network.network.id
	}
}
