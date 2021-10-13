#!/usr/bin/env bash

if [ ! -f "/home/vagrant/.kube/config" ]; then
    echo "> Init k8s admin (kubeadm)"
    HOST_NAME=$(hostname -s)
    echo "> Init k8s admin (kubeadm): ${HOST_NAME} => ${K8S_HEAD_IP}"
    kubeadm init --apiserver-advertise-address=$K8S_HEAD_IP --apiserver-cert-extra-sans=$K8S_HEAD_IP --node-name $HOST_NAME --pod-network-cidr=192.169.0.0/16

    echo "> Set credentials to regular user (vagrant)"
    sudo --user=vagrant mkdir -p /home/vagrant/.kube
    cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
    chown $(id -u vagrant):$(id -g vagrant) /home/vagrant/.kube/config
    chmod 744 /etc/kubernetes/admin.conf

    echo "> Switch 'cgroup-driver' to 'systemd' (cover case when init command resets env flags)"
    export KUBECONFIG=/etc/kubernetes/admin.conf
    sed -i "s/cgroup-driver=cgroupfs/cgroup-driver=systemd/g" /var/lib/kubelet/kubeadm-flags.env
fi

if [ ! -f "/etc/kubeadm_join_cmd.sh" ]; then
    echo "> Create k8s join token"
    kubeadm token create --print-join-command > /etc/kubeadm_join_cmd.sh
    chmod +x /etc/kubeadm_join_cmd.sh
fi

echo "> Remove password for ssh between guest VMs (ONLY FOR PLAYGROUND!)"
sed -i "/^[^#]*PasswordAuthentication[[:space:]]no/c\PasswordAuthentication yes" /etc/ssh/sshd_config

echo "> Restarting services"
systemctl daemon-reload
systemctl restart kubelet
systemctl restart docker
systemctl restart sshd

echo "> Install Helm"
curl -s https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
