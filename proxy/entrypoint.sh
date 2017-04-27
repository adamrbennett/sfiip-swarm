#!/bin/sh

echo $@

/usr/sbin/nginx
/consul-template $@ -template /services.conf.ctmpl:/etc/nginx/conf.d/services.conf:/nginx-reload.sh
