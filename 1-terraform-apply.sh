#!/bin/bash

rm dblab.key

cd terraform
terraform init -backend-config=config.azurerm.tfbackend
terraform apply -auto-approve
cd ..