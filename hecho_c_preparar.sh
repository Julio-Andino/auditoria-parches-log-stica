#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
source hecho_c_comun.sh
mkdir -p "$EVID/externo"
crear_servidor "$SRC"
sql "$SRC" <<'SQL'
CREATE TABLE public.productos (
  id integer PRIMARY KEY,
  producto text NOT NULL,
  stock integer NOT NULL CHECK (stock >= 0),
  precio numeric(10,2) NOT NULL CHECK (precio >= 0)
);
INSERT INTO public.productos VALUES
  (1, 'Guantes', 120, 15.50),
  (2, 'Mascarillas', 200, 8.75),
  (3, 'Jeringas', 80, 5.00),
  (4, 'Gasas', 150, 12.00),
  (5, 'Alcohol', 60, 45.00);
SELECT * FROM public.productos ORDER BY id;
SELECT count(*) AS registros, sum(stock) AS unidades FROM public.productos;
SQL
exportar_datos "$SRC" "$EVID/datos-originales.csv"
sha256sum "$EVID/datos-originales.csv"
echo "OK: base original creada con 5 registros ficticios."
