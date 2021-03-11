# rndc provider
provider "dns" {
	update {
		server        = local.master_ip
		key_name      = var.dns_key
		key_algorithm = "hmac-md5"
		key_secret    = var.dns_key_secret
	}
}

# construct reverse in-arpa strings from address list
data "external" "reverse" {
	# refactor to input QUERY input - i.e be a function
	count	= length(local.data.records)
	program	= ["/bin/bash", "-c", <<-EOF
		echo ${local.data.records[count.index].addr} | { IFS=. read w x y z; echo "[\"$z\",\"$y.$x.$w.in-addr.arpa.\"]"; } | jq '{ "name": .[0], "zone": .[1]}'
	EOF
	]
}

# create A record for each entry
resource "dns_a_record_set" "fwd-record" {
	count		= length(local.data.records)
	name		= local.data.records[count.index].name
	zone		= local.data.zone
	addresses	= [ local.data.records[count.index].addr ]
	ttl		= 86400
	depends_on	= [
		null_resource.dns-service
	]
}

# create PTR record for each entry
resource "dns_ptr_record" "rev-record" {
	count		= length(local.data.records)
	zone		= data.external.reverse[count.index].result.zone
	name		= data.external.reverse[count.index].result.name
	ptr		= "${local.data.records[count.index].name}.${local.data.zone}"
	ttl		= 86400
	depends_on	= [
		null_resource.dns-service
	]
}

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
		master_ip	= local.master_ip
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
			        echo "waiting for pod" && sleep 1;
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
