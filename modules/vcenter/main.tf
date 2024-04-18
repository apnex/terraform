locals {
	prefix			= var.prefix
	vcenter_url		= var.vcenter_url
	vcenter_file		= "${abspath(path.root)}/${local.prefix}-${var.vcenter_file}"
	vcenter_json		= "${abspath(path.root)}/${var.vcenter_json}"
	not_dry_run		= var.not_dry_run
}

# pull file
resource "null_resource" "pull-file" {
	triggers = {
		always_run	= timestamp()
		file_url	= local.vcenter_url
		file_name	= local.vcenter_file
	}
	provisioner "local-exec" {
		interpreter = ["/bin/bash" ,"-c"]
		command = <<-EOT
			if [[ -f "${self.triggers.file_name}" ]]; then
				echo "file EXISTS ${self.triggers.file_name}"
			else
				curl -Lo "${self.triggers.file_name}" "${self.triggers.file_url}"
			fi
		EOT
	}
	provisioner "local-exec" {
		when    = destroy
		command = <<-EOT
			rm "${self.triggers.file_name}"
		EOT
	}
}

# vcenter.create
resource "null_resource" "vcenter-create" {
	depends_on = [
		null_resource.pull-file
	]
	triggers = {
		always_run	= timestamp()
		file_name	= local.vcenter_file
		vcsa_json	= local.vcenter_json
		not_dry_run	= local.not_dry_run
	}
	provisioner "local-exec" {
		interpreter = ["/bin/bash" ,"-c"]
		command = <<-EOT
			if [[ -f "${self.triggers.file_name}" ]]; then
				echo "file EXISTS ${self.triggers.file_name}"
				"${path.module}/vcenter.create.sh" "${self.triggers.file_name}" "${self.triggers.vcsa_json}" "${self.triggers.not_dry_run}"
			else
				echo "file MISSING"
			fi
		EOT
	}
}
