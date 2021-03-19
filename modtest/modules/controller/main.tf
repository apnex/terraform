locals {
	lab			= "lab0${var.vmw.lab_id}"	
	bootfile_url		= var.vmw.controller.bootfile_url
	bootfile_name		= "${local.lab}-${var.vmw.controller.bootfile_name}"
}

data "vsphere_datacenter" "datacenter" {
	name			= var.vmw.datacenter
}

data "vsphere_network" "network" {
	name			= var.vmw.controller.network
	datacenter_id		= data.vsphere_datacenter.datacenter.id
}

data "vsphere_datastore" "datastore" {
	name			= var.vmw.controller.datastore
	datacenter_id		= data.vsphere_datacenter.datacenter.id
}

data "vsphere_vapp_container" "lab" {
	name			= local.lab
	datacenter_id		= data.vsphere_datacenter.datacenter.id
}

# pull file - turn into docker resource?
resource "null_resource" "pull-file" {
	triggers = {
		exists		= fileexists("${path.root}/${local.bootfile_name}")
		pullfilename	= "${path.root}/${local.bootfile_name}"
		pullfileurl	= local.bootfile_url
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
	datacenter       = var.vmw.datacenter
	datastore        = var.vmw.controller.datastore
	source_file      = "${path.root}/${local.bootfile_name}"
	destination_file = "iso/${local.bootfile_name}"
	depends_on = [
		null_resource.pull-file
	]
}

resource "vsphere_virtual_machine" "vm" {
	name				= "${var.vmw.controller.name}.${local.lab}"
	resource_pool_id		= data.vsphere_vapp_container.lab.id
	datastore_id			= data.vsphere_datastore.datastore.id
	wait_for_guest_net_timeout	= 40 # minutes
	depends_on = [
		vsphere_file.push-file
	]
	lifecycle {
		ignore_changes = [
			cdrom
		]
	}

	# connection/provisioner
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
				echo "Waiting for runonce startup scripts.. "
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
		path			= "iso/${local.bootfile_name}"
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
