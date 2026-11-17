#!/usr/bin/env bash
set -euo pipefail
# Solo reemplaza contenedores etiquetados del laboratorio, sin datos de produccion.
for n in 01 02; do
  nombre="logistica-b-srv-$n"
  [[ $(docker inspect -f '{{index .Config.Labels "logistica.hecho-b"}}' "$nombre") == lab ]]
  [[ $(docker exec "$nombre" sh -c '. /etc/os-release; echo "$ID:$VERSION_ID"') == debian:10 ]]
  docker rm -f "$nombre"
  docker run -d --name "$nombre" --label logistica.hecho-b=lab ubuntu:24.04 sleep infinity
  [[ $(docker exec "$nombre" sh -c '. /etc/os-release; echo "$ID:$VERSION_ID"') == ubuntu:24.04 ]]
  echo "SRV-$n: reemplazo Debian 10 -> Ubuntu 24.04 verificado"
done
