# VM_Initial-Setup
**This repository contains ready to run scripts file.**
Do the following things with just one line:
* Create kubeadm cluster using `create_cluster.sh` script file.
* Install Kubeadm using `kubeadm_install.sh` script file.
* Do kubernetes part of openstack-helm deployment using `k8s_common_setup.sh` script file.
* Start your VM using `startup.sh` file as it installs various things like **docker, ansible, minikube, kubeadm, kind, helm, etc.**
* Delete kubeadm cluster using `remove_cluster.sh` script file.

## After cloning the repository:
```
cd VM_Initial-Setup/
```

## Change the mode of the files before executing them.
Run the command:
```
chmod 700 create_cluster.sh kubeadm_install.sh k8s_common_setup.sh startup.sh remove_cluster.sh
```
Now execute the script files according to your need.
1. Startup script
```
./startup.sh
```
2. Kubeadm_install
```
./kubeadm_install.sh
```
3. Kubeadm cluster
```
create_cluster.sh
```

