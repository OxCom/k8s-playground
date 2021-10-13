# K8S Playground

Proof of Concept playground build with Vagrant and K8S

## Install
 0. Check **Vagrantfile** and modify the settings
 1. Run 
    ```bash
    vagrant up
    ```
 2. Install network, metrics, rook and krew (see [/scripts/cluster/](./scripts/cluster) folder)

**NOTE**: WSL2 requires to have ``VM_PARA_PROVIDER = hyperv``, otherwise Vagrant will not be able to work with VirtualBox 

## Links
- [Kubectx](https://github.com/ahmetb/kubectx) - helps you switch between clusters back and forth
- [Krew](https://krew.sigs.k8s.io/) - plugin manager for kubectl command-line tool
- [Helm](https://helm.sh/) - package manager for Kubernetes
- [Rook](https://rook.io/) - distributed storage systems into self-managing, self-scaling, self-healing storage services
- [Vagrant](https://www.vagrantup.com/) - create and configure lightweight, reproducible, and portable development environments
- [Me](https://www.oxcom.me) - whois me
- [Quay](https://quay.io/) - Alternative for Docker images storage from Red Hat
