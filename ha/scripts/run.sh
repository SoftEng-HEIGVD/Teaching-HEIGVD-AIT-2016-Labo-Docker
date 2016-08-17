#!/bin/sh
rsyslogd -c5 2>/dev/null

# TODO: [CFG] Remove the following two lines
sed -i 's/<s1>/$S1_PORT_3000_TCP_ADDR/g' /usr/local/etc/haproxy/haproxy.cfg
sed -i 's/<s2>/$S2_PORT_3000_TCP_ADDR/g' /usr/local/etc/haproxy/haproxy.cfg

# TODO: [CFG] Replace this command
haproxy -f /usr/local/etc/haproxy/haproxy.cfg -p /var/run/haproxy.pid
