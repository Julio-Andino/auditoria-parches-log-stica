#!/usr/bin/env bash
set -euo pipefail
fase=${1:-inicial}
case "$fase" in inicial|final) ;; *) echo 'Uso: bash inventario.sh inicial|final' >&2; exit 1;; esac
mkdir -p evidencias
if [[ "$fase" == inicial ]]; then
  docker pull debian/eol:buster
  docker pull ubuntu:24.04
  docker image inspect debian/eol:buster ubuntu:24.04 > evidencias/imagenes-base.json
  for n in 01 02 03 04 05; do
    nombre="logistica-b-srv-$n"
    if docker container inspect "$nombre" >/dev/null 2>&1; then
      echo "Ya existe $nombre; no se modificara" >&2; exit 1
    fi
  done
  for n in 01 02 03 04 05; do
    imagen=ubuntu:24.04; red=bridge
    if [[ "$n" == 01 || "$n" == 02 ]]; then imagen=debian/eol:buster; red=none; fi
    docker run -d --name "logistica-b-srv-$n" --label logistica.hecho-b=lab --network "$red" "$imagen" sleep infinity
  done
fi
archivo="evidencias/inventario-$fase.csv"
echo 'Servidor,Sistema,Version,Estado' > "$archivo"
eol=0
for n in 01 02 03 04 05; do
  nombre="logistica-b-srv-$n"
  [[ $(docker inspect -f '{{index .Config.Labels "logistica.hecho-b"}}' "$nombre") == lab ]]
  id=$(docker exec "$nombre" sh -c '. /etc/os-release; echo "$ID"')
  version=$(docker exec "$nombre" sh -c '. /etc/os-release; echo "$VERSION_ID"')
  case "$id:$version" in
    debian:10) estado=EOL; eol=$((eol+1));;
    ubuntu:24.04) estado=Vigente;;
    *) echo "Version no prevista: $id:$version" >&2; exit 1;;
  esac
  echo "SRV-$n,$id,$version,$estado" >> "$archivo"
done
cat "$archivo"
echo "Servidores EOL: $eol de 5 ($((eol*20))%)"
if [[ "$fase" == inicial ]]; then test "$eol" -eq 2; else test "$eol" -eq 0; fi
