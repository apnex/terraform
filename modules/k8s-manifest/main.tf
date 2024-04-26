# external md5
data "external" "trigger" {
	program = ["/bin/bash", "-c", <<EOF
		CHECKSUM=$(cat ${path.root}/state/${var.manifest} | md5sum | awk '{ print $1 }')
		jq -n --arg checksum "$CHECKSUM" '{"checksum":$checksum}'
	EOF
	]
}

resource "null_resource" "applied_manifest" {
	triggers = {
		#md5		= data.external.trigger.result["checksum"]
		master_ip	= var.master_ip
		master_ssh_key	= var.master_ssh_key
		manifest_src	= "${path.root}/state/${var.manifest}"
		manifest_dst	= "/root/${var.manifest}"
	}
	connection {
		host		= self.triggers.master_ip
		type		= "ssh"
		user		= "root"
		private_key     = self.triggers.master_ssh_key
	}
	provisioner "file" {
		source      = self.triggers.manifest_src
		destination = self.triggers.manifest_dst
	}
	provisioner "remote-exec" {
		inline	= [<<-EOT
			kubectl apply -f "${self.triggers.manifest_dst}"
		EOT
		]
	}
	provisioner "remote-exec" {
		when = destroy
		inline	= [<<-EOT
			kubectl delete -f "${self.triggers.manifest_dst}"
		EOT
		]
	}
}

resource "null_resource" "healthcheck_pod_ready" {
	triggers = {
		master_ip	= var.master_ip
		master_ssh_key	= var.master_ssh_key
		pod_ready	= var.pod_ready
	}
	connection {
		host		= self.triggers.master_ip
		type		= "ssh"
		user		= "root"
		private_key     = self.triggers.master_ssh_key
	}
	provisioner "remote-exec" {
		inline	= [<<-EOT
			while [[ $(kubectl get pods ${var.pod_ready} -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do
			        echo "waiting for POD [ ${var.pod_ready} ]" && sleep 3;
			done
			kubectl get pods -A
		EOT
		]
	}
	depends_on = [
		null_resource.applied_manifest
	]
}
