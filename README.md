# K8S Playground

Proof of Concept playground build with Vagrant and K8S

## Install
 0. Check **Vagrantfile** and modify the settings
 1. Run 
    ```bash
    vagrant up
    ```
 2. Once cluster up you have to configure network and metrics by your own    

**NOTE**: WSL2 requires to have ``VM_PARA_PROVIDER = hyperv``, otherwise Vagrant will not be able to work with VirtualBox 

## Links
- [kubectx](https://github.com/ahmetb/kubectx) - helps you switch between clusters back and forth
- [krew](https://krew.sigs.k8s.io/) - plugin manager for kubectl command-line tool
- [helm](https://helm.sh/) - package manager for Kubernetes

