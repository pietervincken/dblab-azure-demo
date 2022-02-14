#!/bin/bash

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
sudo apt-get install docker-ce docker-ce-cli containerd.io zfsutils-linux postgresql-client -y


#Optional to start fresh
docker stop dblab_server; 
docker rm dblab_server; 
sudo rm -rf /var/lib/dblab/dblab_pool_01/dump/*;
sudo rm -rf /var/lib/dblab/dblab_pool_01/data; 
sudo rm -rf /var/lib/dblab/dblab_pool_02/dump/*;
sudo rm -rf /var/lib/dblab/dblab_pool_02/data; 
sudo rm -rf /home/adminuser/.dblab/engine/meta;

list=$(lsblk --noheadings --raw | grep 10G | awk '{ print $1 }' | grep -E "^sd[a-z]$")
list=($list)

echo dblab_pool_01=/dev/${list[0]}
# Create ZFS pool
export DBLAB_DISK=/dev/${list[0]}
sudo zpool create -f \
  -O compression=on \
  -O atime=off \
  -O recordsize=128k \
  -O logbias=throughput \
  -m /var/lib/dblab/dblab_pool_01 \
  dblab_pool_01 \
  "${DBLAB_DISK}"

sudo zpool export dblab_pool_01
sudo zpool import -d /dev/disk/by-id dblab_pool_01
sudo zpool import -c /etc/zfs/zpool.cache

echo dblab_pool_02=/dev/${list[1]}
export DBLAB_DISK=/dev/${list[1]}
sudo zpool create -f \
  -O compression=on \
  -O atime=off \
  -O recordsize=128k \
  -O logbias=throughput \
  -m /var/lib/dblab/dblab_pool_02 \
  dblab_pool_02 \
  "${DBLAB_DISK}"

sudo zpool export dblab_pool_02
sudo zpool import -d /dev/disk/by-id dblab_pool_02
sudo zpool import -c /etc/zfs/zpool.cache

zpool list

mkdir -p ~/.dblab/engine/configs

# Install DBLAB
curl https://gitlab.com/postgres-ai/database-lab/-/raw/master/engine/scripts/cli_install.sh | bash
sudo mv ~/.dblab/dblab /usr/local/bin/dblab

sudo groupadd docker
sudo usermod -aG docker $USER