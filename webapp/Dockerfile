FROM node:0.12.2-wheezy
MAINTAINER Laurent Prevost <laurent.prevost@heig-vd.ch>

RUN apt-get update && apt-get -y install wget curl vim && apt-get clean && npm install -g bower

# TODO: Instll S6

# TODO: Install Serf

COPY run.sh run.sh

RUN chmod +x run.sh

COPY app /backend/app

RUN cd /backend/app && npm install && bower install --allow-root

# Clean up.
RUN apt-get clean \
&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

EXPOSE 3000

# TODO: Update this for S6
CMD [ "./run.sh" ]
