read -r -d '' COMMANDS <<-EOF
	kubectl get services -o json | jq -r '.items[] | select(.metadata.name | contains("vip-control-dns-rndc")).status.loadBalancer.ingress[0].ip'
EOF
VALUE=$(sshpass -p 'VMware1!' ssh root@10.30.0.73 -o LogLevel=QUIET -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t "$COMMANDS" | tr -d '\r')
jq -n --arg value "$VALUE" '{"value":$value}'

