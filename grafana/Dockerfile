FROM grafana/grafana

EXPOSE 80

ENV GF_SERVER_HTTP_PORT 80

RUN setcap 'cap_net_bind_service=+ep' /usr/sbin/grafana-server
