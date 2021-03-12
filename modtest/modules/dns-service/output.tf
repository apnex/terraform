output "service-ip" {
	value = data.external.service-ip.result["value"]
}
