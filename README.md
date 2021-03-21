## SYN

### 1) apply {env}
** Time: 25 mins **
```
terraform init
terraform plan
terraform apply -auto-approve
```

### 2) apply {env}->vsphere
** Time: 8 mins**
```
terraform init
terraform plan
terraform apply -auto-approve
```

### 3) apply {env}->services
** Time: 2 mins **
```
terraform init
terraform plan
terraform apply -auto-approve
```

### 4) apply {env}->vcenter
** Time: 30 mins**
Note: ensure that the target esx host fqdn can be resolved  
```
terraform init
terraform plan
terraform apply -auto-approve
```
## FIN
