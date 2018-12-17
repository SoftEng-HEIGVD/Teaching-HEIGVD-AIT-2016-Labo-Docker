# The base image is one of the offical one
FROM node:0.12.2-wheezy

# TODO: [GEN] Replace with your name and email
MAINTAINER Laurent Prevost <laurent.prevost@heig-vd.ch>

# Install the required tools to run our webapp and some utils
RUN apt-get update && apt-get -y install wget curl vim iputils-ping && npm install -g bower

# We copy the application and make sure the dependencies are installed before
# other operations. Doing so will reduce the time required to build this image
# as downloading NPM dependencies can be quite long.
COPY app /backend/app
RUN cd /backend/app && npm install && bower install --allow-root

# TODO: [S6] Install

# TODO: [Serf] Install

# TODO: [S6] Replace the two following instructions
# Copy the starting script and make it executable
COPY scripts /scripts/
RUN chmod +x /scripts/*.sh

# TODO: [Serf] Add Serf S6 setup

# Clean up
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# TODO: [Serf] Expose ports

# Expose the web application port
EXPOSE 3000

# Define an environment variable for the role of the container
ENV ROLE backend

# TODO: [S6] Replace the following instruction
# Command executed when the container starts
CMD [ "/scripts/run.sh" ]
