#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
source hecho_c_comun.sh
es_laboratorio "$SRC"
mkdir -p "$EVID/externo"
# Primera copia: disco del propio contenedor original.
docker exec "$SRC" pg_dump -U postgres -d inventario -Fc -f /tmp/inventario.dump
# Segunda copia: fuera del contenedor, en el almacenamiento del ejecutor.
docker cp "$SRC:/tmp/inventario.dump" "$EVID/externo/inventario.dump"
local_sha=$(docker exec "$SRC" sha256sum /tmp/inventario.dump | cut -d ' ' -f 1)
externo_sha=$(sha256sum "$EVID/externo/inventario.dump" | cut -d ' ' -f 1)
test "$local_sha" = "$externo_sha"
test -s "$EVID/externo/inventario.dump"
(cd "$EVID/externo" && sha256sum inventario.dump > inventario.sha256 && sha256sum -c inventario.sha256)
docker exec "$SRC" pg_restore --list /tmp/inventario.dump > "$EVID/contenido-respaldo.txt"
stat -c 'Tamano del respaldo: %s bytes' "$EVID/externo/inventario.dump"
echo "OK: respaldo local y copia externa al contenedor tienen el mismo SHA-256: $externo_sha"
