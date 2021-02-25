# vsphere_distributed_virtual_switch.dvs:
resource "vsphere_distributed_virtual_switch" "dvs" {
    active_uplinks                    = [
        "Uplink 1",
        "Uplink 2",
        "Uplink 3",
        "Uplink 4",
    ]
    allow_forged_transmits            = false
    allow_mac_changes                 = false
    allow_promiscuous                 = false
    block_all_ports                   = false
    check_beacon                      = false
    #config_version                    = "21"
    custom_attributes                 = {}
    datacenter_id                     = "datacenter-3"
    directpath_gen2_allowed           = false
    egress_shaping_average_bandwidth  = 100000000
    egress_shaping_burst_size         = 104857600
    egress_shaping_enabled            = false
    egress_shaping_peak_bandwidth     = 100000000
    failback                          = true
    faulttolerance_maximum_mbit       = -1
    faulttolerance_reservation_mbit   = 0
    faulttolerance_share_count        = 50
    faulttolerance_share_level        = "normal"
    hbr_maximum_mbit                  = -1
    hbr_reservation_mbit              = 0
    hbr_share_count                   = 50
    hbr_share_level                   = "normal"
    ingress_shaping_average_bandwidth = 100000000
    ingress_shaping_burst_size        = 104857600
    ingress_shaping_enabled           = false
    ingress_shaping_peak_bandwidth    = 100000000
    iscsi_maximum_mbit                = -1
    iscsi_reservation_mbit            = 0
    iscsi_share_count                 = 50
    iscsi_share_level                 = "normal"
    lacp_api_version                  = "multipleLag"
    lacp_enabled                      = false
    lacp_mode                         = "passive"
    link_discovery_operation          = "listen"
    link_discovery_protocol           = "cdp"
    management_maximum_mbit           = -1
    management_reservation_mbit       = 0
    management_share_count            = 50
    management_share_level            = "normal"
    max_mtu                           = 9000
    multicast_filtering_mode          = "snooping"
    name                              = "fabric"
    netflow_active_flow_timeout       = 60
    netflow_collector_port            = 0
    netflow_enabled                   = false
    netflow_idle_flow_timeout         = 15
    netflow_internal_flows_only       = false
    netflow_observation_domain_id     = 0
    netflow_sampling_rate             = 4096
    network_resource_control_enabled  = true
    network_resource_control_version  = "version3"
    nfs_maximum_mbit                  = -1
    nfs_reservation_mbit              = 0
    nfs_share_count                   = 50
    nfs_share_level                   = "normal"
    notify_switches                   = true
    standby_uplinks                   = []
    tags                              = []
    teaming_policy                    = "loadbalance_srcid"
    tx_uplink                         = false
    uplinks                           = [
        "Uplink 1",
        "Uplink 2",
        "Uplink 3",
        "Uplink 4",
    ]
    vdp_maximum_mbit                  = -1
    vdp_reservation_mbit              = 0
    vdp_share_count                   = 50
    vdp_share_level                   = "normal"
    #version                           = "7.0.0"
    virtualmachine_maximum_mbit       = -1
    virtualmachine_reservation_mbit   = 0
    virtualmachine_share_count        = 100
    virtualmachine_share_level        = "high"
    vlan_id                           = 0
    vmotion_maximum_mbit              = -1
    vmotion_reservation_mbit          = 0
    vmotion_share_count               = 50
    vmotion_share_level               = "normal"
    vsan_maximum_mbit                 = -1
    vsan_reservation_mbit             = 0
    vsan_share_count                  = 50
    vsan_share_level                  = "normal"
    host {
        devices        = [
            "vmnic0",
            "vmnic1",
        ]
        host_system_id = "host-1112"
    }
    host {
        devices        = [
            "vmnic0",
            "vmnic1",
        ]
        host_system_id = "host-1113"
    }
    host {
        devices        = [
            "vmnic0",
            "vmnic1",
        ]
        host_system_id = "host-1114"
    }
}

# vsphere_vnic.vmk0_host-1112:
resource "vsphere_vnic" "vmk0_host-1112" {
    distributed_port_group  = "dvportgroup-1147"
    distributed_switch_port = "50 31 b1 00 4e 2f c5 09-3a 40 3b 01 62 93 66 06"
    host                    = "host-1112"
    mac                     = "00:50:56:68:4e:44"
    mtu                     = 9000
    netstack                = "defaultTcpipStack"

    ipv4 {
        dhcp    = false
        ip      = "172.16.10.111"
        netmask = "255.255.255.0"
    }
}

# vsphere_vnic.vmk0_host-1113:
resource "vsphere_vnic" "vmk0_host-1113" {
    distributed_port_group  = "dvportgroup-1147"
    distributed_switch_port = "50 31 b1 00 4e 2f c5 09-3a 40 3b 01 62 93 66 06"
    host                    = "host-1113"
    mac                     = "00:50:56:6a:82:70"
    mtu                     = 9000
    netstack                = "defaultTcpipStack"

    ipv4 {
        dhcp    = false
        ip      = "172.16.10.112"
        netmask = "255.255.255.0"
    }
}

# vsphere_vnic.vmk0_host-1114:
resource "vsphere_vnic" "vmk0_host-1114" {
    distributed_port_group  = "dvportgroup-1147"
    distributed_switch_port = "50 31 b1 00 4e 2f c5 09-3a 40 3b 01 62 93 66 06"
    host                    = "host-1114"
    mac                     = "00:50:56:60:e5:4a"
    mtu                     = 9000
    netstack                = "defaultTcpipStack"

    ipv4 {
        dhcp    = false
        ip      = "172.16.10.113"
        netmask = "255.255.255.0"
    }
}

# vsphere_vnic.vmk1_host-1112:
resource "vsphere_vnic" "vmk1_host-1112" {
    distributed_port_group  = "dvportgroup-1148"
    distributed_switch_port = "50 31 b1 00 4e 2f c5 09-3a 40 3b 01 62 93 66 06"
    host                    = "host-1112"
    mac                     = "00:50:56:63:37:39"
    mtu                     = 9000
    netstack                = "vmotion"

    ipv4 {
        dhcp    = false
        ip      = "172.16.11.111"
        netmask = "255.255.255.0"
    }
}

# vsphere_vnic.vmk1_host-1113:
resource "vsphere_vnic" "vmk1_host-1113" {
    distributed_port_group  = "dvportgroup-1148"
    distributed_switch_port = "50 31 b1 00 4e 2f c5 09-3a 40 3b 01 62 93 66 06"
    host                    = "host-1113"
    mac                     = "00:50:56:65:c3:9f"
    mtu                     = 9000
    netstack                = "vmotion"

    ipv4 {
        dhcp    = false
        ip      = "172.16.11.112"
        netmask = "255.255.255.0"
    }
}

# vsphere_vnic.vmk1_host-1114:
resource "vsphere_vnic" "vmk1_host-1114" {
    distributed_port_group  = "dvportgroup-1148"
    distributed_switch_port = "50 31 b1 00 4e 2f c5 09-3a 40 3b 01 62 93 66 06"
    host                    = "host-1114"
    mac                     = "00:50:56:61:48:70"
    mtu                     = 9000
    netstack                = "vmotion"

    ipv4 {
        dhcp    = false
        ip      = "172.16.11.113"
        netmask = "255.255.255.0"
    }
}

# vsphere_vnic.vmk2_host-1112:
resource "vsphere_vnic" "vmk2_host-1112" {
    distributed_port_group  = "dvportgroup-1149"
    distributed_switch_port = "50 31 b1 00 4e 2f c5 09-3a 40 3b 01 62 93 66 06"
    host                    = "host-1112"
    mac                     = "00:50:56:67:20:fc"
    mtu                     = 9000
    netstack                = "defaultTcpipStack"

    ipv4 {
        dhcp    = false
        gw      = "172.16.12.1"
        ip      = "172.16.12.111"
        netmask = "255.255.255.0"
    }
}

# vsphere_vnic.vmk2_host-1113:
resource "vsphere_vnic" "vmk2_host-1113" {
    distributed_port_group  = "dvportgroup-1149"
    distributed_switch_port = "50 31 b1 00 4e 2f c5 09-3a 40 3b 01 62 93 66 06"
    host                    = "host-1113"
    mac                     = "00:50:56:6c:5e:59"
    mtu                     = 9000
    netstack                = "defaultTcpipStack"

    ipv4 {
        dhcp    = false
        gw      = "172.16.12.1"
        ip      = "172.16.12.112"
        netmask = "255.255.255.0"
    }
}

# vsphere_vnic.vmk2_host-1114:
resource "vsphere_vnic" "vmk2_host-1114" {
    distributed_port_group  = "dvportgroup-1149"
    distributed_switch_port = "50 31 b1 00 4e 2f c5 09-3a 40 3b 01 62 93 66 06"
    host                    = "host-1114"
    mac                     = "00:50:56:68:96:a9"
    mtu                     = 9000
    netstack                = "defaultTcpipStack"

    ipv4 {
        dhcp    = false
        gw      = "172.16.12.1"
        ip      = "172.16.12.113"
        netmask = "255.255.255.0"
    }
}
