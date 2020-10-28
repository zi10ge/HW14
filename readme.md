
terraform plan -var-file=key.tfvars
terraform apply -var-file=key.tfvars -auto-approve
terraform destroy -var-file=key.tfvars -auto-approve



key.tfvars

key_id = "secret"
key_sec = "secret"

