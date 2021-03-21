# construct reverse in-arpa strings from address list
data "external" "reverse" {
	count	= length(var.vmw.records)
	program	= ["/bin/bash", "-c", <<-EOF
		echo ${var.vmw.records[count.index].addr} | { IFS=. read w x y z; echo "[\"$z\",\"$y.$x.$w.in-addr.arpa.\"]"; } | jq '{ "name": .[0], "zone": .[1]}'
	EOF
	]
}

# create A record for each entry
resource "dns_a_record_set" "fwd-record" {
	count		= length(var.vmw.records)
	name		= var.vmw.records[count.index].name
	zone		= var.vmw.zone
	addresses	= [ var.vmw.records[count.index].addr ]
	ttl		= 86400
}

# create PTR record for each entry
resource "dns_ptr_record" "rev-record" {
	count		= length(var.vmw.records)
	zone		= data.external.reverse[count.index].result.zone
	name		= data.external.reverse[count.index].result.name
	ptr		= "${var.vmw.records[count.index].name}.${var.vmw.zone}"
	ttl		= 86400
}
