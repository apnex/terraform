provider "nsxt" {
  host                 = "${var.host}"
  vmc_token            = "${var.vmc_token}"
  allow_unverified_ssl = true
  enforcement_point    = "vmc-enforcementpoint"
}
 
resource "nsxt_policy_security_policy" "policy2" {
  domain       = "cgw"
  display_name = "policy2"
  description  = "Terraform provisioned Security Policy"
  category     = "Application"
 
  rule {
    display_name       = "rule name"
    source_groups      = ["${nsxt_policy_group.mygroup2.path}"]
    action             = "DROP"
    services           = ["${nsxt_policy_service.nico-service_l4port2.path}"]
    logged             = true
  }
}
