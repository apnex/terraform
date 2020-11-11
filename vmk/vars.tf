variable "vsphere_server" {
  type        = string
  description = "vCenter or ESXi host"
}
variable "vsphere_user" {
  type        = string
  description = "User with permissions to create VM"
}
variable "vsphere_password" {
  type        = string
  description = "Defined user password"
}
variable "esxi_hosts" {
  default = [
    "esxi41.rubrik.us",
    "esxi42.rubrik.us",
    "esxi43.rubrik.us",
    "esxi44.rubrik.us"
  ]
}
