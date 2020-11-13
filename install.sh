#!/bin/bash

## install terraform
TFVER=$(curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest | jq -r '.tag_name' | cut -c 2-)
wget https://releases.hashicorp.com/terraform/${TFVER}/terraform_${TFVER}_linux_amd64.zip
unzip terraform_${TFVER}_linux_amd64.zip
chmod 755 terraform
mv terraform /usr/bin/

## bash completion
terraform -install-autocomplete
