output "controller_ip" {
	value = vsphere_virtual_machine.vm.default_ip_address
}

output "controller_id" {
	value = vsphere_virtual_machine.vm.id
}

output "controller_moid" {
	value = vsphere_virtual_machine.vm.moid
}

output "controller_ssh_key" {
	value = local.private_key
}

output "controller_pub_key" {
	value = local.public_key
}
