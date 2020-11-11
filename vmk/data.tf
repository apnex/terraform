data "vsphere_datacenter" "dc" {
  name = "DR"
}
data "vsphere_host" "host" {
  count         = "${length(var.esxi_hosts)}"
  name          = "${var.esxi_hosts[count.index]}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}
data "vsphere_distributed_virtual_switch" "dvs" {
  name          = "DR-DSwitch"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

