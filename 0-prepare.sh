#!/bin/sh

az account set -s $subscription
az group show --name $rgstate || az group create -l $location -n $rgstate
az storage account show --name $sastate || (az storage account create -n $sastate -g $rgstate -l $location --sku Standard_LRS && az storage container create -n tfstate --account-name $sastate --public-access blob --auth-mode login)

rm terraform/config.azurerm.tfbackend

echo "resource_group_name  = \"$rgstate\""          >> terraform/config.azurerm.tfbackend
echo "storage_account_name = \"$sastate\""          >> terraform/config.azurerm.tfbackend
echo 'container_name       = "tfstate"'             >> terraform/config.azurerm.tfbackend
echo 'key                  = "terraform.tfstate"'   >> terraform/config.azurerm.tfbackend