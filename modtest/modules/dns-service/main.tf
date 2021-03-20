# external md5
data "external" "trigger" {
	program = ["/bin/bash", "-c", <<EOF
		#CHECKSUM=$(curl -L https://labops.sh/dns/terraform-dns.yaml | md5sum | awk '{ print $1 }')
		CHECKSUM=$(cat ${path.root}/${var.manifest} | md5sum | awk '{ print $1 }')
		jq -n --arg checksum "$CHECKSUM" '{"checksum":$checksum}'
	EOF
	]
}

# dns-service
resource "null_resource" "dns-service" {
	triggers = {
		md5		= data.external.trigger.result["checksum"]
		master_ip	= var.master_ip
		master_ssh_key	= var.master_ssh_key
		manifest	= var.manifest
	}
	connection {
		host		= self.triggers.master_ip
		type		= "ssh"
		user		= "root"
		private_key     = file(self.triggers.master_ssh_key)
	}
	provisioner "file" {
		source      = "${path.root}/${self.triggers.manifest}"
		destination = "/root/${self.triggers.manifest}"
	}
	provisioner "remote-exec" {
		inline	= [<<-EOT
			kubectl apply -f "/root/${self.triggers.manifest}"
			while [[ $(kubectl get pods control-dns -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do
			        echo "waiting for pod" && sleep 3;
			done
			kubectl get pods -A
			sleep 10 # wait for bind to start
		EOT
		]
	}
	provisioner "remote-exec" {
		when = destroy
		inline	= [
			"kubectl delete -f /root/${self.triggers.manifest}"
		]
	}
}

# retrieve service IP
data "external" "service-ip" {
	program = ["/bin/bash", "-c", <<-EOT
		read -r -d '' COMMANDS <<-EOF
			kubectl get services -o json | jq -r '.items[] | select(.metadata.name | contains("vip-control-dns-rndc")).status.loadBalancer.ingress[0].ip'
		EOF
		VALUE=$(ssh root@"${var.master_ip}" -i "${var.master_ssh_key}" -o LogLevel=QUIET -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t "$COMMANDS" | tr -d '\r')
		#VALUE=$(sshpass -p 'VMware1!' ssh root@"${var.master_ip}" -o LogLevel=QUIET -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t "$COMMANDS" | tr -d '\r')
		jq -n --arg value "$VALUE" '{"value":$value}'
	EOT
	]
	depends_on = [
		null_resource.dns-service
	]
}
