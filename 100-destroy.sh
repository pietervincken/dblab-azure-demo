#!/bin/sh

if [ -z $subscription ]; then
    echo "Could not find subscription. Stopping!"
    exit 1
fi

if [ -z $rgstate ]; then
    echo "Could not find rgstate. Stopping!"
    exit 1
fi

if [ -z $sastate ]; then
    echo "Could not find sastate. Stopping!"
    exit 1
fi

az account set -s $subscription
az storage account show --name $sastate && az storage account delete -n $sastate -g $rgstate -y
az group show --name $rgstate && az group delete -n $rgstate -y