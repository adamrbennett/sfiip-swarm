#!/bin/bash

docker network create -d overlay sfi

docker service create --name roasts-v1 --network sfi -e SERVICE_NAME=roasts -e SERVICE_TAGS=1.0.0 172.31.0.100:5000/roasts:1.0.0

docker service create --name roasts-v2 --network sfi -e SERVICE_NAME=roasts -e SERVICE_TAGS=2.0.0 172.31.0.100:5000/roasts:2.0.0

docker service create --name brews-v1 --network sfi -e SERVICE_NAME=brews -e SERVICE_TAGS=1.0.0 172.31.0.100:5000/brews:1.0.0

docker service create --name menu-v1 --network sfi -e SERVICE_NAME=menu -e SERVICE_TAGS=1.0.0 172.31.0.100:5000/menu:1.0.0

docker service create --name proxy-v1 --mode global --network sfi -p 80:80 -e SERVICE_80_NAME=proxy -e SERVICE_443_NAME=proxy-ssl -e SERVICE_TAGS=1.0.0 172.31.0.100:5000/proxy:1.0.0 -consul=172.17.0.1:8500
