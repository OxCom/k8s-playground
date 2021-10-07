# encoding: utf-8
# -*- mode: ruby -*-
# vi: set ft=ruby :

### configuration parameters

###
# Playground setup
###
VM_GROUP = "K8S - Playground Cluster"
VM_BOX_IMAGE = "ubuntu/focal64"
VM_BOX_VERSION = "20210929.0.0"

###
# Cluster configuration
###
VM_PREFIX = "k8s"

# Setup for compute nodes of the cluster
# K8S requires minimum 2 CPU cores
VM_MASTER_CPU = "2"
VM_MASTER_MEM = "2048"
VM_NODE_CPU = "4"
VM_NODE_MEM = "4096"

# with WSL2 it should be hyper-v: https://www.virtualbox.org/manual/ch08.html#vboxmanage-modifyvm
# WSL2 enabled ? "hyperv" : "kvm"
VM_PARA_PROVIDER = "kvm"

# Number of nodes in cluster
K8S_NODES = 3
# Master IP address (x.y.z.K8S_MASTER)

K8S_IP_START = 10
K8S_NETWORK = "10.100.42"
K8S_HEAD_IP = "#{K8S_NETWORK}.#{K8S_IP_START}"

# Extra disk for K8S node in GB
K8S_NODE_DISK = K8S_NODES * 10

Vagrant.configure("2") do |config|
    config.vm.define "#{VM_PREFIX}-head" do |node|
        node.vm.provision "shell", inline: "echo Configuring node: #{VM_PREFIX}-head"

        node.vm.box = VM_BOX_IMAGE
        node.vm.box_version = VM_BOX_VERSION
        node.vm.hostname = "#{VM_PREFIX}-head"
        node.vm.network :private_network, ip: "#{K8S_HEAD_IP}"

        node.vm.provider "virtualbox" do |v|
            v.name = "#{VM_PREFIX}-head"
            v.customize ["modifyvm", :id, "--groups", "/#{VM_GROUP}"]
            v.customize ["modifyvm", :id, "--cpus", VM_MASTER_CPU]
            v.customize ["modifyvm", :id, "--memory", VM_MASTER_MEM]
            v.customize ["modifyvm", :id, "--paravirtprovider", VM_PARA_PROVIDER]

            # Prevent VirtualBox from interfering with host audio stack
            v.customize ["modifyvm", :id, "--audio", "none"]
        end

        # Provision folders and files
        node.vm.synced_folder "./", "/home/vagrant/k8s"

        # Install/setup base services on VM
        node.vm.provision :shell, path: "./scripts/k8s-base.sh", env: {"K8S_HEAD_IP" => K8S_HEAD_IP, "K8S_VM_IP" => K8S_HEAD_IP}

        # Install/setup related services on VM
        node.vm.provision :shell, path: "./scripts/k8s-head.sh", env: {"K8S_HEAD_IP" => K8S_HEAD_IP, "K8S_VM_IP" => K8S_HEAD_IP}

        # path docker certs to  vagrant instance
        if File.directory?(File.expand_path("./certs.d/"))
            config.vm.synced_folder "./certs.d", "/etc/docker/certs.d"
        end
    end

    (1..K8S_NODES).each do |i|
        vm_name = "#{VM_PREFIX}-node-#{i}"
        vm_ip = K8S_IP_START + i

        config.vm.define "#{vm_name}" do |node|
            node.vm.provision "shell", inline: "echo Configuring node: #{vm_name}"

            node.vm.box = VM_BOX_IMAGE
            node.vm.box_version = VM_BOX_VERSION
            node.vm.hostname = vm_name
            node.vm.network :private_network, ip: "#{K8S_NETWORK}.#{vm_ip}"

            node.vm.provider "virtualbox" do |v|
                v.name = vm_name
                v.customize ["modifyvm", :id, "--groups", "/#{VM_GROUP}"]
                v.customize ["modifyvm", :id, "--cpus", VM_NODE_CPU]
                v.customize ["modifyvm", :id, "--memory", VM_NODE_MEM]
                v.customize ["modifyvm", :id, "--paravirtprovider", VM_PARA_PROVIDER]

                # Prevent VirtualBox from interfering with host audio stack
                v.customize ["modifyvm", :id, "--audio", "none"]

                # see https://www.virtualbox.org/manual/ch08.html#vboxmanage-storageattach
                # Disk 100GB
                disk_name = ".vagrant/disks/disk-#{vm_name}.vdb"
                unless File.exist?(disk_name)
                    v.customize ["createhd", "--filename", disk_name, "--size", K8S_NODE_DISK * 1024 ]
                end

                v.customize [ "storageattach", :id, "--storagectl", "SCSI", "--port", 3, "--device", 0, "--type", "hdd", "--medium", disk_name ]
            end

            # Install/setup base services on VM
            node.vm.provision :shell, path: "./scripts/k8s-base.sh", env: {"K8S_HEAD_IP" => K8S_HEAD_IP, "K8S_VM_IP" => "#{K8S_NETWORK}.#{vm_ip}"}

            # Install/setup related services on VM
            node.vm.provision :shell, path: "./scripts/k8s-node.sh", env: {"K8S_HEAD_IP" => K8S_HEAD_IP, "K8S_VM_IP" => "#{K8S_NETWORK}.#{vm_ip}"}

            # path docker certs to  vagrant instance
            if File.directory?(File.expand_path("./certs.d/"))
                config.vm.synced_folder "./certs.d", "/etc/docker/certs.d"
            end
        end
    end
end
