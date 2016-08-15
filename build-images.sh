#!/bin/bash

# Build the haproxy image
echo "************************  build haproxy image  ************************"
cd /vagrant/ha
sudo docker build -t softengheigvd/ha .

# Build the webapp image
echo "************************  build webapp image  ************************"
cd /vagrant/webapp
sudo docker build -t softengheigvd/webapp .
