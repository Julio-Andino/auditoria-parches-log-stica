#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
source hecho_c_comun.sh
# Este script solo elimina el contenedor de laboratorio identificado.
es_laboratorio "$SRC"
(cd "$EVID/externo" && sha256sum -c inventario.sha256)
echo 'Simulacion de perdida del servidor original y su respaldo local.'
docker rm -fv "$SRC"
if docker container inspect "$SRC" >/dev/null 2>&1; then
  echo 'ERROR: el origen sigue existiendo.' >&2; exit 1
fi
echo 'OK: el contenedor original ya no existe.'
inicio=$(date +%s)
crear_servidor "$DST"
# Base vacia en un segundo contenedor; se recupera solo desde la copia externa.
docker cp "$EVID/externo/inventario.dump" "$DST:/tmp/inventario.dump"
docker exec "$DST" pg_restore -U postgres -d inventario --exit-on-error --single-transaction /tmp/inventario.dump
fin=$(date +%s)
echo "Tiempo medido de creacion y restauracion del destino: $((fin-inicio)) segundos" | tee "$EVID/tiempo-recuperacion.txt"
echo 'OK: restauracion completada desde la copia externa al origen.'
