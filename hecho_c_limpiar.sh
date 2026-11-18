#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
source hecho_c_comun.sh
for nombre in "$SRC" "$DST"; do
  if docker container inspect "$nombre" >/dev/null 2>&1; then
    if es_laboratorio "$nombre"; then
      docker rm -fv "$nombre"
    else
      echo "Se omite $nombre: no pertenece al laboratorio." >&2
    fi
  fi
done
