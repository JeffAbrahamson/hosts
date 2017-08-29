


## postgresql

## influxdb

### influxdb server

### telegraf client

I want to run a telegraf client on each of my hosts, including p27.
The telegraf client needs to know a password to connect to the
influxdb server (cf. srd p27-influxdb):  search for
================username================ and
================password================ and replace with user and
pass.

Telegraf is configured to listen on localhost to udp port 8095
(inputs.socket_listener).  This is unsecured and only for local
processes: the port should remain blocked by ufw.

Hosts that run additional services may (should) uncomment additional
inputs.


## grafana

## letsencrypt
