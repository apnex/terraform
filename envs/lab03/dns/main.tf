# install dns-service
module "dns-service" {
	source			= "../../../modules/dns-service"
	master_ip		= local.master_ip
	master_ssh_key		= local.master_ssh_key
	manifest		= local.manifest
}

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
		module.dns-service
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
		module.dns-service,
		dns_a_record_set.fwd-record
	]
}
