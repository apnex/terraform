locals {
	ssh_key_name	= var.ssh_key_name
	ssh_host	= var.ssh_host
	ssh_user	= var.ssh_user
	ssh_password	= var.ssh_password
}

resource "tls_private_key" "ssh" {
	algorithm = "RSA"
	rsa_bits  = 4096
}

resource "local_sensitive_file" "pem_file" {
	filename		= pathexpand("./${local.ssh_key_name}.pem")
	file_permission		= "600"
	directory_permission	= "700"
	content			= tls_private_key.ssh.private_key_pem
}

resource "local_sensitive_file" "ssh_file" {
	filename		= pathexpand("./${local.ssh_key_name}.ssh")
	file_permission		= "600"
	directory_permission	= "700"
	content			= tls_private_key.ssh.public_key_openssh
}

resource "null_resource" "authorized_key" {
	triggers = {
		public_ssh_key	= tls_private_key.ssh.public_key_openssh
		host		= local.ssh_host
		user		= local.ssh_user
		password	= local.ssh_password
	}
	connection {
		host		= self.triggers.host
		user		= self.triggers.user
		password	= self.triggers.password
	}
	provisioner "remote-exec" {
		inline	= [<<-EOT
			mkdir -p /root/.ssh
			touch /root/.ssh/authorized_keys
			printf "%s" '${self.triggers.public_ssh_key}' >> /root/.ssh/authorized_keys
		EOT
		]
	}
	provisioner "remote-exec" {
		when	= destroy
		inline	= [<<-EOT
			MYESCAPED='${self.triggers.public_ssh_key}'
			ESCAPED_KEYWORD=$(echo "$MYESCAPED" | sed -e 's/[]\/$*.^[]/\\&/g');
			sed -i.bak "/$ESCAPED_KEYWORD/d" /root/.ssh/authorized_keys
		EOT
		]
	}
}
