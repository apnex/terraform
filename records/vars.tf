variable "dns_ip" {
	default = "10.30.0.86"
}
variable "dns_key" {
	default = "dnsctl."
}
variable "dns_key_secret" {
	# echo -n 'VMware1!' | base64
	default = "Vk13YXJlMSE="
}

variable "vmw" {
	default = {
		zone = "lab01.syd."
		records = [
			{
				name = "esx11"
				addr = "10.30.0.111"
			},
			{
				name = "esx12"
				addr = "10.30.0.112"
			},
			{
				name = "esx13"
				addr = "10.30.0.113"
			},
			{
				name = "esx14"
				addr = "10.30.0.114"
			}
		]
	}
}

