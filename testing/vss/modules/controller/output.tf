output "ip" {
	value = vsphere_virtual_machine.vm.default_ip_address
}

output "id" {
	value = vsphere_virtual_machine.vm.id
}

output "moid" {
	value = vsphere_virtual_machine.vm.moid
}

output "ssh_key" {
	value = local.private_key
}

output "pub_key" {
	value = local.public_key
}
