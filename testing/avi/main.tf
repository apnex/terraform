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

data "avi_sslprofile" "system_standard_sslprofile" {
	name = "System-Standard"
}

data "avi_vrfcontext" "global_vrf" {
	name = "global"
}

resource "avi_networkprofile" "test_networkprofile" {
	name		= "tf-networkprofile-obi-42"
	tenant_ref	= data.avi_tenant.default_tenant.id
	profile {
		type = "PROTOCOL_TYPE_TCP_PROXY"
	}
}

resource "avi_applicationpersistenceprofile" "test_applicationpersistenceprofile" {
	name			= "tf-applicationpersistence-obi-42"
	tenant_ref		= data.avi_tenant.default_tenant.id
	persistence_type	= "PERSISTENCE_TYPE_CLIENT_IP_ADDRESS"
}

resource "avi_vsvip" "test_vsvip" {
	name		= "tf-vip-obi-42"
	cloud_ref	= data.avi_cloud.default_cloud.id
	tenant_ref	= data.avi_tenant.default_tenant.id
	vip {
		vip_id = "0"
		auto_allocate_ip  = true
		avi_allocated_vip = true
	}
}

resource "avi_virtualservice" "test_vs" {
	name			= "tf-vs-obi-vmw"
	pool_ref		= avi_pool.testpool.id
	cloud_ref		= data.avi_cloud.default_cloud.id
	tenant_ref		= data.avi_tenant.default_tenant.id
	application_profile_ref	= data.avi_applicationprofile.system_http_profile.id
	network_profile_ref	= data.avi_networkprofile.system_tcp_profile.id
	vsvip_ref		= avi_vsvip.test_vsvip.id
	services {
		port		= 80
		enable_ssl	= false
		port_range_end	= 80
	}
	cloud_type		= "CLOUD_VCENTER"
	se_group_ref		= data.avi_serviceenginegroup.se_group.id
	analytics_profile_ref	= data.avi_analyticsprofile.system_analytics_profile.id
	vrf_context_ref		= data.avi_vrfcontext.global_vrf.id
}

resource "avi_healthmonitor" "test_hm_1" {
	name = "tf-obi-healthmonitor-42"
	type = "HEALTH_MONITOR_HTTP"
}

resource "avi_pool" "testpool" {
	name					= "tf-obi-pool-42"
	health_monitor_refs			= [ avi_healthmonitor.test_hm_1.id ]
	cloud_ref				= data.avi_cloud.default_cloud.id
	tenant_ref				= data.avi_tenant.default_tenant.id
	application_persistence_profile_ref	= avi_applicationpersistenceprofile.test_applicationpersistenceprofile.id
	fail_action {
		type = "FAIL_ACTION_CLOSE_CONN"
	}
}

resource "avi_server" "test_server1" {
	ip       = "10.79.186.200"
	port     = "80"
	pool_ref = avi_pool.testpool.id
	hostname = "foo1"
}
resource "avi_server" "test_server2" {
	ip       = "10.79.186.202"
	port     = "80"
	pool_ref = avi_pool.testpool.id
	hostname = "foo2"
}
