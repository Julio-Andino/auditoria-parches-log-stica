#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
source hecho_c_comun.sh
exportar_datos "$DST" "$EVID/datos-restaurados.csv"
if ! diff -u "$EVID/datos-originales.csv" "$EVID/datos-restaurados.csv"; then
  echo 'ERROR: los datos recuperados no coinciden.' >&2; exit 1
fi
sql "$DST" -c 'SELECT * FROM public.productos ORDER BY id;'
sql "$DST" -c 'SELECT count(*) AS registros, sum(stock) AS unidades FROM public.productos;'
registros=$(sql "$DST" -At -c 'SELECT count(*) FROM public.productos;')
unidades=$(sql "$DST" -At -c 'SELECT sum(stock) FROM public.productos;')
test "$registros" = 5
test "$unidades" = 610
# Verificar que se conservaron las restricciones de la tabla.
restricciones=$(sql "$DST" -At -c "SELECT count(*) FROM pg_constraint WHERE conrelid = 'public.productos'::regclass AND contype IN ('p','c');")
test "$restricciones" = 3
sha256sum "$EVID/datos-originales.csv" "$EVID/datos-restaurados.csv"
echo 'OK: los cinco registros, sus valores y las restricciones verificadas coinciden.'
echo 'RESULTADO FINAL: RESPALDO Y RESTAURACION VERIFICADOS'
echo 'Alcance: datos ficticios; no demuestra RPO/RTO ni recuperacion real de la empresa.'
