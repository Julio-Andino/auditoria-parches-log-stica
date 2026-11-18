#!/usr/bin/env bash
# Funciones comunes. Ejecutar desde la raiz del repositorio.
set -euo pipefail
export LC_ALL=C
SRC=logistica-c-original
DST=logistica-c-recuperacion
EVID=evidencias-hecho-c
IMAGE=postgres:17
LABEL=logistica.hecho-c

es_laboratorio() {
  [[ "$(docker inspect --format '{{ index .Config.Labels "logistica.hecho-c" }}' "$1")" == laboratorio ]]
}

crear_servidor() {
  local nombre=$1
  if docker container inspect "$nombre" >/dev/null 2>&1; then
    echo "ERROR: ya existe el contenedor $nombre; no se modifica." >&2
    return 1
  fi
  # Contrasena temporal: no se imprime ni se publica en el repositorio.
  local POSTGRES_PASSWORD
  POSTGRES_PASSWORD=$(openssl rand -hex 32)
  export POSTGRES_PASSWORD
  docker run -d --name "$nombre" --label "$LABEL=laboratorio" \
    --network none -e POSTGRES_PASSWORD -e POSTGRES_DB=inventario "$IMAGE"
  # Esperar al servidor definitivo, no al servidor temporal de inicializacion.
  for ((i=1; i<=60; i++)); do
    if docker exec "$nombre" pg_isready -h 127.0.0.1 -U postgres -d inventario >/dev/null 2>&1; then
      docker exec "$nombre" psql -X -U postgres -d inventario -v ON_ERROR_STOP=1 -c 'SELECT version();'
      return 0
    fi
    sleep 1
  done
  echo "ERROR: PostgreSQL no disponible en $nombre" >&2
  return 1
}

sql() {
  local nombre=$1; shift
  es_laboratorio "$nombre"
  docker exec -i "$nombre" psql -X -U postgres -d inventario -v ON_ERROR_STOP=1 "$@"
}

exportar_datos() {
  sql "$1" -q -c 'COPY (SELECT id, producto, stock, precio FROM public.productos ORDER BY id) TO STDOUT WITH CSV HEADER;' > "$2"
}
