#!/bin/bash

cd terraform
terraform init -backend-config=config.azurerm.tfbackend
terraform destroy -auto-approve
cd ..

# Remove work files
rm vm/server.yml
rm dblab.key