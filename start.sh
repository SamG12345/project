#!/bin/sh

sudo sed -i "s|http://de.archive.ubuntu.com/ubuntu/|http://archive.ubuntu.com/ubuntu/|" /etc/apt/sources.list
sudo apt update && \
sudo apt install -y docker.io openssh-server net-tools nmap && \
snap install kubectl && \
snap install minikube && \
minikube start


bash install_docker.sh
