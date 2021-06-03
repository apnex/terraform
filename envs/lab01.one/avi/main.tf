terraform {                                                                        
	required_providers {
		avi = {
			source  = "vmware/avi"
			version = ">= 20.1.5"
		}
	}
}

// Configure the AVI provider
provider "avi" {
	avi_controller	= var.avi_controller
	avi_username	= var.avi_username
	avi_password	= var.avi_password
	avi_tenant	= "admin"
	avi_version	= "20.1.5"
}

data "avi_tenant" "tenant" {
	name = var.tenant
}

data "avi_cloud" "default" {
        name		= "Default-Cloud"
}
resource "avi_network" "ls-vip-pool" {
        name			= "ls-vip-pool"
	cloud_ref		= data.avi_cloud.default.id
	dhcp_enabled		= false
	ip6_autocfg_enabled	= false
	configured_subnets {
		prefix {
			ip_addr {
				addr = "172.16.20.0"
				type = "V4"
			}
			mask = 24
		}
		static_ip_ranges {
			type  = "STATIC_IPS_FOR_VIP"
			range {
				begin {
					addr = "172.16.20.101"
					type = "V4"
				}
				end {
					addr = "172.16.20.199"
					type = "V4"
				}
			}
		}
	}
}

resource "avi_ipamdnsproviderprofile" "tf-dns-vmw" {
	name	= "tf-dns-vmw"
	type	= "IPAMDNS_TYPE_INTERNAL_DNS"
	internal_profile {
		dns_service_domain {
			domain_name  = "lb.lab01.one"
			pass_through = false
			record_ttl   = 30
		}
	}
}

resource "avi_ipamdnsproviderprofile" "tf-ipam-vmw" {
	name	= "tf-ipam-vmw"
	type	= "IPAMDNS_TYPE_INTERNAL"
	internal_profile {
		usable_networks {
			nw_ref = avi_network.ls-vip-pool.id
		}
	}
}

resource "avi_cloud" "vmware_cloud" {
	name         = var.cloud_name
	vtype        = "CLOUD_VCENTER"
	tenant_ref   = data.avi_tenant.tenant.id
	license_tier = var.vcenter_license_tier
	license_type = var.vcenter_license_type
	dhcp_enabled = true
	vcenter_configuration {
		username		= var.vcenter_configuration.username
		password		= var.vcenter_configuration.password
		vcenter_url		= var.vcenter_configuration.vcenter_url
		datacenter		= var.vcenter_configuration.datacenter
		management_network	= var.vcenter_configuration.management_network
		privilege		= var.vcenter_configuration.privilege
	}
	dns_provider_ref = avi_ipamdnsproviderprofile.tf-dns-vmw.id
	ipam_provider_ref = avi_ipamdnsproviderprofile.tf-ipam-vmw.id
}
