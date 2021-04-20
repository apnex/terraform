locals {
	clusters = [
		"domain-c307",
		"domain-c308"
	]
	xmlstring = join("", [
		for cluster in local.clusters: "<${cluster}><enabled>false</enabled></${cluster}>"
	])
}

# vcenter advanced settings
resource "null_resource" "vcenter-enabled-bash" {
	triggers = {
		vcenter		= "vcenter.lab02.syd"
		username	= "root"
		password	= "VMware1!SDDC"
	}
	connection {
		host		= self.triggers.vcenter
		type		= "ssh"
		user		= self.triggers.username
		password	= self.triggers.password
		agent		= false
	}
	# set shell to /bin/bash for root
	provisioner "local-exec" {
		command = <<-EOT
			read -r -d '' COMMANDS <<-EOF
				shell
				chsh -s /bin/bash root
			EOF
			sshpass -p ${self.triggers.password} ssh root@${self.triggers.vcenter} -o LogLevel=QUIET -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t "$COMMANDS"
		EOT
	}
	# set shell to /bin/appliancesh for root
	provisioner "local-exec" {
		when = destroy
		command = <<-EOT
			read -r -d '' COMMANDS <<-EOF
				chsh -s /bin/appliancesh root
			EOF
			sshpass -p ${self.triggers.password} ssh root@${self.triggers.vcenter} -o LogLevel=QUIET -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t "$COMMANDS"
		EOT
	}
}

# vcenter advanced settings
resource "null_resource" "vcenter-advanced-settings" {
	triggers = {
		vcenter		= "vcenter.lab02.syd"
		username	= "root"
		password	= "VMware1!SDDC"
		xmlstring	= local.xmlstring
	}
	connection {
		host		= self.triggers.vcenter
		type		= "ssh"
		user		= self.triggers.username
		password	= self.triggers.password
		agent		= false
	}
	## remove add section
	provisioner "remote-exec" {
		inline	= [<<-EOT
			read -r -d '' XSLT <<-EOF
				<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
					<xsl:output omit-xml-declaration="yes" indent="yes"/>
					<xsl:template match="config">
						<xsl:copy>
							<xsl:apply-templates select="@*" />
								<vcls>
									<clusters>
										${self.triggers.xmlstring}
									</clusters>
								</vcls>
							<xsl:apply-templates select="node()" />
						</xsl:copy>
					</xsl:template>
					<xsl:template match="node()|@*" name="identity">
						<xsl:copy>
							<xsl:apply-templates select="node()|@*"/>
						</xsl:copy>
					</xsl:template>
					<xsl:template match="vcls"/>
				</xsl:stylesheet>
			EOF
			# backup previous vpxd.cfg
			cp /etc/vmware-vpx/vpxd.cfg /etc/vmware-vpx/vpxd.old
			echo -n "$XSLT" | xsltproc - /etc/vmware-vpx/vpxd.old | xmllint --format - | sed '1d' > /etc/vmware-vpx/vpxd.cfg
			service-control --restart vpxd
		EOT
		]
	}
	## remove vcls section
	provisioner "remote-exec" {
		when = destroy
		inline	= [<<-EOT
			read -r -d '' XSLT <<-EOF
				<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
					<xsl:output omit-xml-declaration="yes" indent="yes"/>
					<xsl:template match="node()|@*" name="identity">
						<xsl:copy>
							<xsl:apply-templates select="node()|@*"/>
						</xsl:copy>
					</xsl:template>
					<xsl:template match="vcls"/>
				</xsl:stylesheet>
			EOF
			# backup previous vpxd.cfg
			cp /etc/vmware-vpx/vpxd.cfg /etc/vmware-vpx/vpxd.old
			echo -n "$XSLT" | xsltproc - /etc/vmware-vpx/vpxd.old | xmllint --format - | sed '1d' > /etc/vmware-vpx/vpxd.cfg
			service-control --restart vpxd
		EOT
		]
	}
	depends_on = [
		null_resource.vcenter-enabled-bash
	]
}
