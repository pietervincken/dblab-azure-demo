#!/bin/sh

az keyvault secret download --vault-name kvdblabdemo --name private -f ~/.ssh/dblab.key
chmod 0600 ~/.ssh/dblab.key
ip=$(az network public-ip show -g rg-dblabdemo -n pip-dblabdemo | jq --raw-output '.ipAddress')

ssh adminuser@$ip -i ~/.ssh/dblab.key

scp -i ~/.ssh/dblab.key $PWD/server.yml adminuser@$ip:/home/adminuser/.dblab/engine/configs/server.yml