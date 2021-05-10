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
	avi_controller = "c1.avidemo.vmware.com"
	avi_username	= "admin"
	avi_password	= "avi123$%"
	avi_tenant	= "Sales"
	avi_version	= "20.1.4"
}

data "avi_applicationprofile" "system_http_profile" {
	name = "System-HTTP"
}

data "avi_applicationprofile" "system_https_profile" {
	name = "System-Secure-HTTP"
}

data "avi_tenant" "default_tenant" {
	name = "Sales"
}

data "avi_cloud" "default_cloud" {
	name = "vmware_cloud"
}

data "avi_serviceenginegroup" "se_group" {
	name = "Default-Group"
}

data "avi_networkprofile" "system_tcp_profile" {
	name = "System-TCP-Proxy"
}

data "avi_analyticsprofile" "system_analytics_profile" {
	name = "System-Analytics-Profile"
}

data "avi_sslkeyandcertificate" "system_default_cert" {
	name = "System-Default-Cert"
}

data "avi_sslprofile" "system_standard_sslprofile" {
	name = "System-Standard"
}

data "avi_vrfcontext" "global_vrf" {
	name = "global"
}

resource "avi_networkprofile" "network_profile1" {
  name = "tf-network-profile"
  profile {
    type = "PROTOCOL_TYPE_TCP_PROXY"
    tcp_proxy_profile {
      ignore_time_wait = false
      time_wait_delay = 2000
      max_retransmissions = 8
      max_syn_retransmissions = 8
      automatic = true
      receive_window = 64
      nagles_algorithm = false
      ip_dscp = 0
      reorder_threshold = 10
      min_rexmt_timeout = 100
      idle_connection_type = "KEEP_ALIVE"
      idle_connection_timeout = 600
      use_interface_mtu = true
      cc_algo = "CC_ALGO_NEW_RENO"
      aggressive_congestion_avoidance = false
      slow_start_scaling_factor = 1
      congestion_recovery_scaling_factor = 2
      reassembly_queue_size = 0
      keepalive_in_halfclose_state = true
      auto_window_growth = true
    }
  }
  connection_mirror = false
  tenant_ref = data.avi_tenant.default_tenant.id
}

resource "avi_applicationprofile" "application_profile1" {
  name = "terraform_http_application_profile"
  type = "APPLICATION_PROFILE_TYPE_HTTP"
  http_profile {
      hsts_enabled = false
      secure_cookie_enabled = false
      httponly_enabled = false
      http_to_https = false
      server_side_redirect_to_https = false
      x_forwarded_proto_enabled = false
      post_accept_timeout = 30000
      client_header_timeout = 10000
      client_body_timeout = 30000
      keepalive_timeout = 30000
      client_max_header_size = 12
      client_max_request_size = 48
      client_max_body_size = 0
      cache_config {
        enabled = false
        xcache_header = true
        age_header = true
        date_header = true
        min_object_size = 100
        max_object_size = 4194304
        default_expire = 600
        heuristic_expire = false
        max_cache_size = 0
        query_cacheable = false
        aggressive = false
        ignore_request_cache_control = false
    }
  }
  tenant_ref = data.avi_tenant.default_tenant.id
}

resource "avi_pool" "lb_pool" {
  name         = "tf-obi-pool"
  lb_algorithm = var.lb_algorithm
  servers {
    ip {
          type = "V4"
      addr = var.server1_ip
    }
    port = var.server1_port
  }
  cloud_ref =  data.avi_cloud.default_cloud.id
  tenant_ref = data.avi_tenant.default_tenant.id
}

resource "avi_poolgroup" "poolgroup1" {
  name         = var.poolgroup_name
  members {
        pool_ref = avi_pool.lb_pool.id
        ratio = 100
  }
  cloud_ref =  data.avi_cloud.default_cloud.id
  tenant_ref = data.avi_tenant.default_tenant.id
}

resource "avi_vsvip" "test_vsvip" {
  name = "terraform-vip"
  vip {
    vip_id = "0"
    ip_address {
      type = "V4"
      addr = var.avi_terraform_vs_vip
    }
  }
  cloud_ref =  data.avi_cloud.default_cloud.id
  tenant_ref = data.avi_tenant.default_tenant.id
}

resource "avi_virtualservice" "http_vs" {
  name                          = "tf-vs-test"
  pool_group_ref                = avi_poolgroup.poolgroup1.id
  tenant_ref                    = data.avi_tenant.default_tenant.id
  vsvip_ref                     = avi_vsvip.test_vsvip.id
  cloud_ref                     = avi_cloud.cloud_none.id
  application_profile_ref       = avi_applicationprofile.application_profile1.id
  network_profile_ref           = avi_networkprofile.network_profile1.id
  services {
    port           = 80
    enable_ssl     = false
  }
}
