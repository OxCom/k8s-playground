#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if [ ! -f "/home/vagrant/.kube/config" ]; then
    echo "> Init k8s admin (kubeadm)"
    HOST_NAME=$(hostname -s)
    echo "> Init k8s admin (kubeadm): ${HOST_NAME} => ${K8S_HEAD_IP}"
    kubeadm init --apiserver-advertise-address=$K8S_HEAD_IP --apiserver-cert-extra-sans=$K8S_HEAD_IP --node-name $HOST_NAME

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

# https://krew.sigs.k8s.io/docs/user-guide/setup/install/
echo "> Install Krew"
(
  set -x; cd "$(mktemp -d)" &&
  OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
  ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
  curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/krew.tar.gz" &&
  tar zxvf krew.tar.gz &&
  KREW=./krew-"${OS}_${ARCH}" &&
  "$KREW" install krew
)

export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

echo '> Install Krew plugins'
kubectl krew install ctx
kubectl krew install ns

echo "> Install Helm"
curl -s https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
