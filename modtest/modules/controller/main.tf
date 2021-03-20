locals {
	lab			= "lab0${var.vmw.lab_id}"	
	bootfile_url		= var.vmw.controller.bootfile_url
	bootfile_name		= "${local.lab}-${var.vmw.controller.bootfile_name}"
	private_key		= var.vmw.controller.private_key
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

# generate local sshkey
resource "null_resource" "generate-sshkey" {
	provisioner "local-exec" {
		command = "yes y | ssh-keygen -b 4096 -t rsa -C 'root' -N '' -f ${var.vmw.controller.private_key}"
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
		source      = var.vmw.controller.public_key
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
		inline = [<<-EOF
			echo "Creating authorized_keys.. "
			mkdir -p /root/.ssh/
			chmod 700 /root/.ssh
			mv /tmp/authorized_keys /root/.ssh/authorized_keys
			chmod 600 /root/.ssh/authorized_keys
			cat /root/.ssh/authorized_keys
		EOF
		]
		connection {
			host		= self.default_ip_address
			type		= "ssh"
			user		= "root"
			password	= "VMware1!"
		}
	}
	provisioner "remote-exec" {
		inline = [<<-EOF
			while [ ! -f /root/startup.done ]; do
				sleep 9;
				echo "Waiting for runonce startup scripts.. "
			done
			hostnamectl set-hostname router
			docker version
			docker ps
		EOF
		]
		connection {
			host		= self.default_ip_address
			type		= "ssh"
			user		= "root"
			private_key     = file("${path.root}/${local.private_key}")
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
