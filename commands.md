<!-- docker service create --name consul -p 8500:8500 --network sfi -e SERVICE_IGNORE=true consul -->

<!-- docker run -d --name registry -p 5000:5000 registry:2 -->

<!-- docker run -d --name consul --net=host -e SERVICE_IGNORE=true -e 'CONSUL_LOCAL_CONFIG={"leave_on_terminate": true}' consul agent -bind=172.31.1.100 -retry-join=172.31.0.100 -->

<!-- docker service create --name consul --mode global -e 'CONSUL_LOCAL_CONFIG={"leave_on_terminate": true}' consul agent -bind=0.0.0.0 -retry-join=172.31.0.100 -->

<!-- docker service create --name registrator --mode global --mount type=bind,source=/var/run/docker.sock,destination=/tmp/docker.sock gliderlabs/registrator -internal consul://172.31.0.100:8500 -->

<!-- docker run -d --name registrator --net=host -v /var/run/docker.sock:/tmp/docker.sock gliderlabs/registrator -internal consul://127.0.0.1:8500 -->

<!-- docker network create -d overlay sfi -->

<!-- docker service create --name registrator --mode global \
  --hostname="{{.Task.Name}}-{{.Task.Slot}}" \
  --mount type=bind,src=/var/run/docker.sock,dst=/tmp/docker.sock \
  gliderlabs/registrator -internal -cleanup consul://172.17.0.1:8500 -->

docker service create --with-registry-auth --name cadvisor --mode global -p 8080:8080 --network sfi \
  --mount type=bind,src=/,dst=/rootfs,ro=true \
  --mount type=bind,src=/var/run,dst=/var/run \
  --mount type=bind,src=/sys,dst=/sys,ro=true \
  --mount type=bind,src=/var/lib/docker,dst=/var/lib/docker,ro=true \
  google/cadvisor:latest

docker service create --with-registry-auth --name node-exporter --mode global --network sfi \
  -e SERVICE_80_NAME=node-exporter \
  -e SERVICE_9100_IGNORE=true \
  --mount type=bind,src=/proc,dst=/host/proc \
  --mount type=bind,src=/sys,dst=/host/sys \
  --mount type=bind,src=/,dst=/rootfs \
  --mount type=bind,src=/etc/hostname,dst=/etc/host_name \
  pointsource/node-exporter \
    -web.listen-address :80 \
    -collector.procfs /host/proc \
    -collector.sysfs /host/sys \
    -collector.filesystem.ignored-mount-points "^/(sys|proc|dev|host|etc)($|/)" \
    -collector.textfile.directory /etc/node-exporter/ \
    -collectors.enabled="conntrack,diskstats,entropy,filefd,filesystem,loadavg,mdadm,meminfo,netdev,netstat,stat,textfile,time,vmstat,ipvs"

docker service create --with-registry-auth --name metrics --network sfi --dns 172.17.0.1 \
  -e SERVICE_80_NAME=metrics \
  -e SERVICE_9090_IGNORE=true \
  pointsource/metrics

docker service create --with-registry-auth --name grafana --network sfi --dns 172.17.0.1 \
  -e SERVICE_3000_IGNORE=true \
  -e SERVICE_80_NAME=grafana \
  -e GF_SECURITY_ADMIN_PASSWORD=letmein \
  -e GF_USERS_ALLOW_SIGN_UP=false \
  pointsource/grafana

docker service create --name portainer --dns 172.17.0.1 --network sfi \
  --constraint 'node.role == manager' \
  --mount type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
  portainer/portainer \
  -H tcp://172.17.0.1:2375 \
  -p :80

docker service create --with-registry-auth --name proxy --mode global \
  --network sfi --dns 172.17.0.1 -p 80:80 -p 443:443 \
  -e SERVICE_80_NAME=proxy -e SERVICE_443_NAME=proxy-ssl \
  pointsource/proxy -consul=172.17.0.1:8500

docker service create --with-registry-auth --name jenkins --network sfi --dns 172.17.0.1 --group 999 \
  --secret source=jenkins_ssh,target=id_rsa \
  -e SERVICE_50000_IGNORE=true \
  -e SERVICE_8080_IGNORE=true \
  -e SERVICE_80_NAME=jenkins \
  --mount type=bind,src=/usr/bin/docker,dst=/usr/bin/docker \
  --mount type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
  pointsource/jenkins \
    --httpPort=80

<!-- docker service create --name roasts-v1 --network sfi -e SERVICE_NAME=roasts -e SERVICE_TAGS=1.0.0 172.31.0.100:5000/roasts:1.0.0

docker service create --name roasts-v2 --network sfi -e SERVICE_NAME=roasts -e SERVICE_TAGS=2.0.0 172.31.0.100:5000/roasts:2.0.0

docker service create --name brews-v1 --network sfi -e SERVICE_NAME=brews -e SERVICE_TAGS=1.0.0 172.31.0.100:5000/brews:1.0.0 -->
