output "controller_ip" {
	value = module.controller.controller_ip
}
output "controller_id" {
	value = module.controller.controller_id
}
output "controller_moid" {
	value = module.controller.controller_moid
}
output "controller_ssh_key" {
	value = "${path.cwd}/${module.controller.controller_ssh_key}"
}

