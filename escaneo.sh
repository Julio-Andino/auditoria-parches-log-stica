#!/usr/bin/env bash
set -euo pipefail
imagen=${1:?Indique imagen Docker local}
nombre=${2:?Indique nombre del reporte}
[[ "$nombre" =~ ^[a-zA-Z0-9_-]+$ ]]
mkdir -p evidencias
docker image inspect "$imagen" --format '{{.Id}}' > "evidencias/$nombre-id.txt"
trivy image --image-src docker --scanners vuln --pkg-types os --exit-code 0 --format json --output "evidencias/$nombre.json" "$imagen"
trivy convert --format table "evidencias/$nombre.json" | tee "evidencias/$nombre.txt"
