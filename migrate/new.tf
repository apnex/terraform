# vsphere_host_virtual_switch.vswitch_host-1112:
resource "vsphere_host_virtual_switch" "vswitch_host-1112" {
    active_nics               = [
        "vmnic0",
    ]
    allow_forged_transmits    = false
    allow_mac_changes         = false
    allow_promiscuous         = false
    beacon_interval           = 1
    check_beacon              = false
    failback                  = true
    host_system_id            = "host-1112"
    link_discovery_operation  = "listen"
    link_discovery_protocol   = "cdp"
    mtu                       = 1500
    name                      = "vSwitch0"
    network_adapters          = [
        "vmnic0",
    ]
    notify_switches           = true
    number_of_ports           = 128
    shaping_average_bandwidth = 0
    shaping_burst_size        = 0
    shaping_enabled           = false
    shaping_peak_bandwidth    = 0
    standby_nics              = []
    teaming_policy            = "loadbalance_srcid"
}

# vsphere_host_virtual_switch.vswitch_host-1113:
resource "vsphere_host_virtual_switch" "vswitch_host-1113" {
    active_nics               = [
        "vmnic0",
    ]
    allow_forged_transmits    = false
    allow_mac_changes         = false
    allow_promiscuous         = false
    beacon_interval           = 1
    check_beacon              = false
    failback                  = true
    host_system_id            = "host-1113"
    link_discovery_operation  = "listen"
    link_discovery_protocol   = "cdp"
    mtu                       = 1500
    name                      = "vSwitch0"
    network_adapters          = [
        "vmnic0",
    ]
    notify_switches           = true
    number_of_ports           = 128
    shaping_average_bandwidth = 0
    shaping_burst_size        = 0
    shaping_enabled           = false
    shaping_peak_bandwidth    = 0
    standby_nics              = []
    teaming_policy            = "loadbalance_srcid"
}

# vsphere_host_virtual_switch.vswitch_host-1114:
resource "vsphere_host_virtual_switch" "vswitch_host-1114" {
    active_nics               = [
        "vmnic0",
    ]
    allow_forged_transmits    = false
    allow_mac_changes         = false
    allow_promiscuous         = false
    beacon_interval           = 1
    check_beacon              = false
    failback                  = true
    host_system_id            = "host-1114"
    link_discovery_operation  = "listen"
    link_discovery_protocol   = "cdp"
    mtu                       = 1500
    name                      = "vSwitch0"
    network_adapters          = [
        "vmnic0",
    ]
    notify_switches           = true
    number_of_ports           = 128
    shaping_average_bandwidth = 0
    shaping_burst_size        = 0
    shaping_enabled           = false
    shaping_peak_bandwidth    = 0
    standby_nics              = []
    teaming_policy            = "loadbalance_srcid"
}

# vsphere_vnic.vmk0_host-1112:
resource "vsphere_vnic" "vmk0_host-1112" {
    host      = "host-1112"
    mac       = "00:50:56:68:4e:44"
    mtu       = 1500
    netstack  = "defaultTcpipStack"
    portgroup = "vss-mgmt"

    ipv4 {
        dhcp    = false
        ip      = "172.16.10.111"
        netmask = "255.255.255.0"
    }
}

# vsphere_vnic.vmk0_host-1113:
resource "vsphere_vnic" "vmk0_host-1113" {
    host      = "host-1113"
    mac       = "00:50:56:6a:82:70"
    mtu       = 1500
    netstack  = "defaultTcpipStack"
    portgroup = "vss-mgmt"

    ipv4 {
        dhcp    = false
        ip      = "172.16.10.112"
        netmask = "255.255.255.0"
    }
}

# vsphere_vnic.vmk0_host-1114:
resource "vsphere_vnic" "vmk0_host-1114" {
    host      = "host-1114"
    mac       = "00:50:56:60:e5:4a"
    mtu       = 1500
    netstack  = "defaultTcpipStack"
    portgroup = "vss-mgmt"

    ipv4 {
        dhcp    = false
        ip      = "172.16.10.113"
        netmask = "255.255.255.0"
    }
}
