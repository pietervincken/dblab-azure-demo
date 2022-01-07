#!/bin/sh

# Install Docker
sudo apt-get update
sudo apt-get install \
ca-certificates \
curl \
gnupg \
lsb-release -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io zfsutils-linux -y

# Create ZFS pool
export DBLAB_DISK=/dev/sdc
sudo zpool create -f \
  -O compression=on \
  -O atime=off \
  -O recordsize=128k \
  -O logbias=throughput \
  -m /var/lib/dblab/dblab_pool \
  dblab_pool \
  "${DBLAB_DISK}"

# Install DBLAB
curl https://gitlab.com/postgres-ai/database-lab/-/raw/master/scripts/cli_install.sh | bash
sudo mv ~/.dblab/dblab /usr/local/bin/dblab

mkdir -p ~/.dblab/engine/configs

curl https://gitlab.com/postgres-ai/database-lab/-/raw/v3.0.0/configs/config.example.logical_generic.yml \
  --output ~/.dblab/engine/configs/server.yml

#Start DBLAB
sudo docker run \
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

dblab init \
  --environment-id=tutorial \
  --url=http://localhost:2345 \
  --token=xx \
  --insecure