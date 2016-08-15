#!/bin/bash

# Update the package index
echo "************************  apt-get update  ************************"
sudo apt-get update

# Install util packages
echo "************************  install git  ************************"
sudo apt-get install git socat -y

# Install Docker
echo "************************  install docker  ************************"
wget -qO- https://get.docker.com/ | sh
sudo usermod -aG docker vagrant

# Build the haproxy image
echo "************************  build haproxy image  ************************"
cd /vagrant/ha
sudo docker build -t softengheigvd/ha .

# Build the webapp image
echo "************************  build webapp image  ************************"
cd /vagrant/webapp
sudo docker build -t softengheigvd/webapp .

# Run two webapps
echo "************************  run webapps  ************************"
sudo docker rm -f s1 2>/dev/null || true
sudo docker rm -f s2 2>/dev/null || true
sudo docker run -d --restart=always -e "TAG=s1" --name s1 softengheigvd/webapp
sudo docker run -d --restart=always -e "TAG=s2" --name s2 softengheigvd/webapp

# Run load balancer
echo "************************  run haproxy  ************************"
sudo docker rm -f ha 2>/dev/null || true
sudo docker run -d -p 80:80 -p 1936:1936 -p 9999:9999 --restart=always -v /supervisor:/supervisor --link s1 --link s2 --name ha softengheigvd/ha

