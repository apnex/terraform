locals {
	lab			= "lab0${var.vmw.lab_id}"	
	bootfile_url		= var.vmw.controller.bootfile_url
	bootfile_name		= "${local.lab}-${var.vmw.controller.bootfile_name}"
	bootfile_path		= join("/", [abspath(path.root), "state/${local.bootfile_name}"])
	private_key		= join("/", [abspath(path.root), "state/${local.lab}-${var.vmw.controller.private_key}"])
	public_key		= "${local.private_key}.pub"
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

# external md5
#check if exist
## if not, download
## return md5
## if yes
## return md5
#data "external" "trigger" {
#	program = ["/bin/bash", "-c", <<EOF
#		CHECKSUM=$(cat ${path.root}/${var.manifest} | md5sum | awk '{ print $1 }')
#		jq -n --arg checksum "$CHECKSUM" '{"checksum":$checksum}'
#	EOF
#	]
#}

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

# generate local sshkey
resource "null_resource" "generate-sshkey" {
	provisioner "local-exec" {
		command = "yes y | ssh-keygen -b 4096 -t rsa -C 'root' -N '' -f ${local.private_key}"
	}
}

# upload file
resource "vsphere_file" "push-file" {
	datacenter       = var.vmw.datacenter
	datastore        = var.vmw.controller.datastore
	source_file      = local.bootfile_path
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
		vsphere_file.push-file,
		null_resource.generate-sshkey
	]
	lifecycle {
		ignore_changes = [
			cdrom
		]
	}

	# copy public key to vm
	provisioner "file" {
		source      = local.public_key
		destination = "/tmp/authorized_keys"
		connection {
			host		= self.default_ip_address
			type		= "ssh"
			user		= "root"
			password	= "VMware1!"
		}
	}
	# enable authorized_keys
	provisioner "remote-exec" {
		inline = [<<-EOT
			echo "Creating authorized_keys.. "
			mkdir -p /root/.ssh/
			chmod 700 /root/.ssh
			mv /tmp/authorized_keys /root/.ssh/authorized_keys
			chmod 600 /root/.ssh/authorized_keys
			cat /root/.ssh/authorized_keys
		EOT
		]
		connection {
			host		= self.default_ip_address
			type		= "ssh"
			user		= "root"
			password	= "VMware1!"
		}
	}
	provisioner "remote-exec" {
		inline = [<<-EOT
			while [ ! -f /root/startup.done ]; do
				sleep 9;
				echo "Waiting for runonce startup scripts.. "
			done
			hostnamectl set-hostname router
			docker version
			docker ps
		EOT
		]
		connection {
			host		= self.default_ip_address
			type		= "ssh"
			user		= "root"
			private_key     = file(local.private_key)
		}
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
