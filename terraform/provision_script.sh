#!/bin/bash

# config git user
git config --global user.name $1
git config --global user.email $2

git config user.name
git config user.email

# install resolvconf
sudo apt-get install resolvconf -y

# chmod script
chmod u+x /home/ubuntu/tokamak-titan-simple-cluster/scripts/run-simple-cluster.sh
chmod u+x /home/ubuntu/tokamak-titan-simple-cluster/scripts/install_minikube.sh

# install minikube
source /home/ubuntu/tokamak-titan-simple-cluster/scripts/install_minikube.sh
