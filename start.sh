#!/bin/sh

sudo sed -i "s|http://de.archive.ubuntu.com/ubuntu/|http://archive.ubuntu.com/ubuntu/|" /etc/apt/sources.list
sudo apt update && \
sudo apt install -y curl docker.io openssh-server net-tools nmap && \
snap install kubectl && \
curl -LO https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-amd64 && \
sudo install minikube-linux-amd64 /usr/local/bin/minikube && rm minikube-linux-amd64 

minikube start



bash install_docker.sh
