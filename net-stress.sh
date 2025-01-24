#!/bin/bash

# Número de réplicas que quieres ejecutar
REPLICAS=1
REPLICAS2=20
# Dirección del servicio de destino
TARGET_URL="http://a23ca4c965b334d70adc426a4739bd78-1276965498.eu-west-3.elb.amazonaws.com/"

# Crear contenedores en paralelo
for i in $(seq 1 $REPLICAS); do
  docker run -d --rm --name load-generator-$i httpd:alpine /bin/sh -c "apk add --no-cache apache2-utils && while true; do ab -n 10000000 -c 100000 $TARGET_URL; done"
done

for i in $(seq 1 $REPLICAS2); do
  docker run -d --rm --name load-generatorv2-$i httpd:alpine /bin/sh -c "apk add --no-cache apache2-utils && while true; do wget --no-cache -q -O- $TARGET_URL; done"
done
