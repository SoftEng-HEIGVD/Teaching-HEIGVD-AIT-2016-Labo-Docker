# Base image is the Official HAProxy
FROM haproxy:1.5

# TODO: [GEN] Replace with your name and email
MAINTAINER Laurent Prevost <laurent.prevost@heig-vd.ch>

# Install some tools
# TODO: [HB] Update to install required tool to install NodeJS
RUN apt-get update && apt-get -y install wget curl vim iputils-ping rsyslog

# TODO: [S6] Install

# TODO: [Serf] Install

# TODO: [HB] Install NodeJS

# TODO: [HB] Install Handlebars

# TODO: [S6] Replace the two following instructions
# Copy all the scripts and make them executable
COPY scripts/ /scripts/
RUN chmod +x /scripts/*.sh

# TODO: [Serf] Add Serf S6 setup

# TODO: [Serf] Copy events handler scripts

# Copy the haproxy and syslog config
COPY config/haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg
COPY config/rsyslogd.cfg /etc/rsyslog.d/49-haproxy.conf

# TODO: [HB] Copy the haproxy configuration template

# Clean up
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# TODO: [CFG] Create the nodes folder

# TODO: [Serf] Expose ports

# Expose the HA proxy ports
EXPOSE 80 1936

# Define an environment variable
ENV ROLE balancer

# TODO: [S6] Replace the following instruction
# Command executed when the container starts
CMD [ "/scripts/run.sh" ]
