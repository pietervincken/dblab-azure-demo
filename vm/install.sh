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
sudo apt-get install docker-ce docker-ce-cli containerd.io zfsutils-linux postgresql-client -y

# Create ZFS pool
export DBLAB_DISK=/dev/sdc
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

export DBLAB_DISK=/dev/sdd
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

mkdir -p ~/.dblab/engine/configs

# Install DBLAB
curl https://gitlab.com/postgres-ai/database-lab/-/raw/master/engine/scripts/cli_install.sh | bash
sudo mv ~/.dblab/dblab /usr/local/bin/dblab

sudo groupadd docker
sudo usermod -aG docker $USER