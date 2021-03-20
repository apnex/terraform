#!/bin/bash
(cat /dev/zero | ssh-keygen -q -N "" -f ~/.ssh/lab02.key) 1>/dev/null 2>/dev/null
#echo "SSH-KEYGEN FINISHED"
cat /root/.ssh/lab02.key
#\cp /root/.ssh/id_rsa.pub /home/rke/.ssh/authorized_keys
#chown -R rke:docker /home/rke
#ssh -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" rke@localhost << EOT
#	docker version
#EOT

