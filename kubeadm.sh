#!/bin/sh

sudo sed -i "s|http://de.archive.ubuntu.com/ubuntu/|http://archive.ubuntu.com/ubuntu/|" /etc/apt/sources.list
sudo apt update > /dev/null
sudo apt install -y curl docker.io openssh-server net-tools nmap > /dev/null
sudo usermod -aG docker $USER
newgrp docker

curl -LO https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube && rm minikube-linux-amd64 
minikube start

# If the directory `/etc/apt/keyrings` does not exist, it should be created before the curl command, read the note below.
# sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.36/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# This overwrites any existing configuration in /etc/apt/sources.list.d/kubernetes.list
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.36/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update > /dev/null
sudo apt-get install -y kubelet kubeadm kubectl > /dev/null
sudo apt-mark hold kubelet kubeadm kubectl > /dev/null

# --------helm--------
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4
chmod 700 get_helm.sh
./get_helm.sh
# -------dashboard via helm-------
helm repo add headlamp https://kubernetes-sigs.github.io/headlamp/
helm repo update
# -------install in the kube system-------
helm install my-headlamp headlamp/headlamp --namespace kube-system
# ---------p-f---------
kubectl port-forward -n kube-system svc/my-headlamp 8080:80
helm install my-headlamp headlamp/headlamp --namespace kube-system

# -------prometheus----------
LATEST=$(curl -s https://api.github.com/repos/prometheus-operator/prometheus-operator/releases/latest | jq -cr .tag_name)
kubectl apply -f https://github.com/prometheus-operator/prometheus-operator/releases/download/${LATEST}/bundle.yaml
LATEST=$(curl -s https://github.com/prometheus/prometheus/tags | grep latest)
kubectl apply -f https://github.com/prometheus-operator/prometheus-operator/releases/download/${LATEST}/bundle.yaml
