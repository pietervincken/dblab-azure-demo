#!/bin/bash

test -f dblab.key || (az keyvault secret download --vault-name kvdblabdemo --name private -f dblab.key && chmod 0600 dblab.key)
ip=$(az network public-ip show -g rg-dblabdemo -n pip-dblabdemo | jq --raw-output '.ipAddress')
token=$(az keyvault secret show --vault-name kvdblabdemo --name token --query 'value')

#Start DBLAB
ssh adminuser@$ip -i dblab.key docker run \
  --name dblab_server \
  --label dblab_control \
  --privileged \
  --publish 127.0.0.1:2345:2345 \
  --volume /var/run/docker.sock:/var/run/docker.sock \
  --volume /var/lib/dblab:/var/lib/dblab/:rshared \
  --volume /home/adminuser/.dblab/engine/configs:/home/dblab/configs:ro \
  --volume /home/adminuser/.dblab/engine/meta:/home/dblab/meta \
  --volume /var/lib/dblab/dblab_pool/dump:/var/lib/dblab/dblab_pool/dump \
  --volume /sys/kernel/debug:/sys/kernel/debug:rw \
  --volume /lib/modules:/lib/modules:ro \
  --volume /proc:/host_proc:ro \
  --env DOCKER_API_VERSION=1.41 \
  --detach \
  --restart on-failure \
  postgresai/dblab-server:3.0.0

ssh adminuser@$ip -i dblab.key dblab init \
  --environment-id=dblabdemo \
  --url=http://localhost:2345 \
  --token=$token \
  --insecure

ssh adminuser@$ip -i dblab.key dblab instance status