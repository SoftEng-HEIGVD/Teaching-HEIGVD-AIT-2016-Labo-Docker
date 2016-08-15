#!/bin/bash

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
