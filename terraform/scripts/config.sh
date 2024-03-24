#!/bin/bash
sudo su

# upgrade
apt update
apt upgrade -y
apt install -y git

# ops agent
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
sudo bash add-google-cloud-ops-agent-repo.sh --also-install
rm add-google-cloud-ops-agent-repo.sh

# Install Docker
apt install -y ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# create scripts for server
mkdir /opt/scripts
gsutil -m cp -r gs://aria-minecraft-server/scripts/* /opt/scripts/

# mount minecraft data disk
sudo mkdir -p /mnt/disks/aria-data-disk
sudo mount -o discard,defaults /dev/sdb /mnt/disks/aria-data-disk

# run minecraft docker image
sudo docker run --privileged -d -v /mnt/disks/aria-data-disk/:/data \
    -e TYPE=FORGE -e MEMORY=25G -e DEBUG=true \
    -e ENABLE_AUTOSTOP=TRUE -e AUTOSTOP_TIMEOUT_EST=600\
    -e VERSION=1.19.2 -e FORGE_VERSION=43.2.0 \
    -p 25565:25565 -e EULA=TRUE --name mc itzg/minecraft-server:java17

# send the IP address
sleep 2m
nohup bash /opt/scripts/notify.sh </dev/null &>/dev/null &

# autodestroy when CPU usage is low
nohup bash /opt/scripts/auto_destroy.sh </dev/null &>/dev/null &

