#!/bin/sh

az account set -s $subscription
az storage account show --name $sastate && az storage account delete -n $sastate -g $rgstate -y
az group show --name $rgstate && az group delete -n $rgstate -y