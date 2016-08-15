FROM haproxy:1.5
MAINTAINER Laurent Prevost <laurent.prevost@heig-vd.ch>

RUN apt-get update && apt-get -y install wget curl vim rsyslog && apt-get clean

# TODO: Install S6

# TODO: Install Serf

COPY scripts/ /scripts/

RUN chmod +x /scripts/*.sh

COPY config/ /config/

# TODO: Copy the scripts for S6

# TODO: Update the way the configuration is managed
RUN ln -s /config/haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg
RUN ln -s /config/rsyslogd.cfg /etc/rsyslog.d/49-haproxy.conf

# TODO: Update this for S6
CMD [ "/scripts/run.sh" ]
