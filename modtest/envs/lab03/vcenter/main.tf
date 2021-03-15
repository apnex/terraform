locals {
	lab			= "lab0${var.vmw.lab_id}"	
}

# pull file
resource "null_resource" "pull-file" {
	triggers = {
		always_run	= timestamp()
		pullfilename	= "vcenter.iso"
		pullfileurl	= var.vmw.files.vcenter
		lab		= local.lab
	}
	provisioner "local-exec" {
		interpreter = ["/bin/bash" ,"-c"]
		command = <<-EOF
			if [[ -f "${self.triggers.pullfilename}" ]]; then
				echo "file EXISTS ${self.triggers.pullfilename}"
			else
				curl -Lo ./"${self.triggers.lab}-${self.triggers.pullfilename}" "${self.triggers.pullfileurl}"
			fi
		EOF
	}
	provisioner "local-exec" {
		when    = destroy
		command = <<-EOF
			rm "${self.triggers.lab}-${self.triggers.pullfilename}"
		EOF
	}
}

# vcenter.create
resource "null_resource" "vcenter-create" {
	depends_on = [
		null_resource.pull-file
	]
	triggers = {
		always_run	= timestamp()
		filename	= "${local.lab}-vcenter.iso"
	}
	provisioner "local-exec" {
		interpreter = ["/bin/bash" ,"-c"]
		command = <<-EOF
			if [[ -f "${self.triggers.filename}" ]]; then
				echo "file EXISTS ${self.triggers.filename}"
				./vcenter.create.sh "${self.triggers.filename}" true
			else
				echo "file MISSING"
			fi
		EOF
	}
}
