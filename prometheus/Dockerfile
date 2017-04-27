FROM prom/prometheus

EXPOSE 80

COPY ./prometheus.yml /etc/prometheus/prometheus.yml

CMD ["-web.listen-address", "0.0.0.0:80", "-config.file", "/etc/prometheus/prometheus.yml"]
