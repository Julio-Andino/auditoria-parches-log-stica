import json
from collections import Counter
from pathlib import Path
import csv

base = Path('evidencias')
niveles = ('CRITICAL', 'HIGH', 'MEDIUM', 'LOW', 'UNKNOWN')
filas = []
for nombre in ['debian-inicial', 'ubuntu-inicial'] + [f'srv-{n:02d}-final' for n in range(1, 6)]:
    reporte = json.loads((base / f'{nombre}.json').read_text())
    resultados = reporte.get('Results') or []
    os_resultados = [r for r in resultados if r.get('Class') == 'os-pkgs']
    if not os_resultados:
        raise RuntimeError(f'{nombre}: no hay resultados de paquetes del SO; no interpretar como cero')
    conteo = Counter(v.get('Severity', 'UNKNOWN') for r in os_resultados for v in (r.get('Vulnerabilities') or []))
    fila = [nombre, *(conteo[n] for n in niveles), sum(conteo.values())]
    filas.append(fila)
    print(nombre, dict(zip((*niveles, 'TOTAL'), fila[1:])))
with (base / 'comparacion-final.csv').open('w', newline='') as f:
    writer = csv.writer(f)
    writer.writerow(['Imagen', *niveles, 'TOTAL'])
    writer.writerows(filas)
print('Fin de la comparacion. Conteos de detecciones paquete-CVE, no CVE unicos.')
print('La migracion y los parches no garantizan cero vulnerabilidades.')
