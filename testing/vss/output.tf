## outputs
#output "datacenter" {
#	value = data.vsphere_datacenter.datacenter.id
#}
#output "resource_pool" {
#	value = data.vsphere_resource_pool.pool.id
#}
#output "host" {
#	value = data.vsphere_host.esx.id
#}
#output "switch" {
#	value = vsphere_host_virtual_switch.switch.id
#}

## controller outputs
output "controller_ip" {
	value = module.controller.ip
}

output "controller_id" {
	value = module.controller.id
}

output "controller_moid" {
	value = module.controller.moid
}

output "controller_ssh_key" {
	value = module.controller.ssh_key
}

output "controller_pub_key" {
	value = module.controller.pub_key
}

output "ssh_string" {
	value = "ssh -i ${module.controller.ssh_key} root@${module.controller.ip}"
}
