#!/bin/bash

mkdir ~/.ssh
cp /run/secrets/id_rsa ~/.ssh
chmod 400 ~/.ssh/id_rsa

exec /bin/tini -- /usr/local/bin/jenkins.sh $@
