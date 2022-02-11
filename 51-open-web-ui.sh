#!/bin/sh

ip=$(az network public-ip show -g rg-dblabdemo -n pip-dblabdemo --query 'ipAddress' -o tsv)

open http://$ip:2346

token=$(az keyvault secret show --vault-name kvdblabdemo --name token --query 'value' -o tsv)
echo "token: $token"