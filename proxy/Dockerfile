FROM nginx:stable-alpine

EXPOSE 80

COPY consul-template-0.15.0-linux-amd64 /consul-template
COPY entrypoint.sh /entrypoint.sh
COPY nginx-reload.sh /nginx-reload.sh
COPY services.conf.ctmpl /services.conf.ctmpl

RUN \
  rm -f /etc/nginx/conf.d/default.conf && \
  chmod +x /consul-template && \
  chmod +x /entrypoint.sh && \
  chmod +x /nginx-reload.sh

ENTRYPOINT ["/entrypoint.sh"]
