#!/bin/sh

test -f dblab.key || (az keyvault secret download --vault-name kvdblabdemo --name private -f dblab.key && chmod 0600 dblab.key)
ip=$(az network public-ip show -g rg-dblabdemo -n pip-dblabdemo | jq --raw-output '.ipAddress')

ssh adminuser@$ip -i dblab.key