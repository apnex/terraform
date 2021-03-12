# external md5
data "external" "trigger" {
	program = ["/bin/bash", "-c", <<EOF
		CHECKSUM=$(curl -L https://labops.sh/dns/terraform-dns.yaml | md5sum | awk '{ print $1 }')
		jq -n --arg checksum "$CHECKSUM" '{"checksum":$checksum}'
	EOF
	]
}

# dns-service
resource "null_resource" "dns-service" {
	triggers = {
		md5		= data.external.trigger.result["checksum"]
		master_ip	= var.master_ip
	}
	connection {
		type		= "ssh"
		user		= "root"
		password	= "VMware1!"
		host		= self.triggers.master_ip
	}
	provisioner "remote-exec" {
		inline	= [<<EOF
			kubectl apply -f https://labops.sh/dns/terraform-dns.yaml
			while [[ $(kubectl get pods control-dns -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do
			        echo "waiting for pod" && sleep 3;
			done
			kubectl get pods -A
			sleep 10 # wait for bind to start
		EOF
		]
	}
	provisioner "remote-exec" {
		when = destroy
		inline	= [
			"kubectl delete -f https://labops.sh/dns/terraform-dns.yaml"
		]
	}
}

# retrieve service IP
data "external" "service-ip" {
	program = ["/bin/bash", "-c", <<-EOT
		read -r -d '' COMMANDS <<-EOF
			kubectl get services -o json | jq -r '.items[] | select(.metadata.name | contains("vip-control-dns-rndc")).status.loadBalancer.ingress[0].ip'
		EOF
		VALUE=$(sshpass -p 'VMware1!' ssh root@"${var.master_ip}" -o LogLevel=QUIET -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t "$COMMANDS" | tr -d '\r')
		jq -n --arg value "$VALUE" '{"value":$value}'
	EOT
	]
	depends_on = [
		null_resource.dns-service
	]
}
