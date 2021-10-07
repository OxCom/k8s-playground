#!/usr/bin/env bash

echo "> Install sshpass"

# Use SSHPass to automate inputting password on password authentication.
add-apt-repository universe
apt-get update
apt-get install -y sshpass

echo "> Join to cluster"
sshpass -p "vagrant" scp -o StrictHostKeyChecking=no vagrant@${K8S_HEAD_IP}:/etc/kubeadm_join_cmd.sh .
chmod +x kubeadm_join_cmd.sh
sh ./kubeadm_join_cmd.sh

echo "> Restarting services"
systemctl daemon-reload
systemctl restart kubelet
systemctl restart docker
