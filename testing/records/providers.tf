provider "dns" {
	update {
		server        = var.dns_ip
		key_name      = var.dns_key
		key_algorithm = "hmac-md5"
		key_secret    = var.dns_key_secret
	}
}
