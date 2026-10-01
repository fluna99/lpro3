#!/usr/bin/env bash
# Material complementario - Repositorio de artefactos propio (sin contenedores ni servicios).
#
# Publica los paquetes .deb generados por CPack en un repositorio APT local
# servido por HTTP. Con esto el equipo controla que version esta instalada en
# cada maquina y puede revertir una entrega en un solo comando.
set -euo pipefail

PROYECTO=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
INFRA="${TALLER_INFRA:-$HOME/taller-infra}"
APT="$INFRA/apt"
PUERTO="${PUERTO_APT:-8080}"

mkdir -p "$APT/pool"

echo "==> Publicando artefactos en $APT/pool"
encontrados=0
while IFS= read -r paquete; do
    [ -e "$paquete" ] || continue
    cp -f "$paquete" "$APT/pool/"
    echo "    $(basename "$paquete")"
    encontrados=$((encontrados + 1))
done < <(find "$PROYECTO/build/artefactos" -maxdepth 1 -name '*.deb' -type f | sort)
[ "$encontrados" -gt 0 ] || { echo "No hay paquetes .deb. Ejecute antes scripts/20-pipeline.sh"; exit 1; }

echo "==> Generando el indice del repositorio"
cd "$APT"
dpkg-scanpackages --multiversion pool /dev/null > Packages
gzip -9cf Packages > Packages.gz
cat > Release <<RELEASE
Origin: Laboratorio de Proyectos UMA
Label: telemetria
Suite: estable
Codename: taller
Architectures: $(dpkg --print-architecture)
Components: main
Description: Repositorio de artefactos del equipo
Date: $(date -Ru)
RELEASE

echo "==> Contenido publicado:"
grep -E '^(Package|Version|Filename):' Packages | sed 's/^/    /'

cat <<INSTRUCCIONES

Repositorio listo en $APT

1) Servirlo (dejar esta orden ejecutandose en otra terminal):
     cd $APT && python3 -m http.server $PUERTO

2) Darlo de alta en una maquina cliente:
     echo "deb [trusted=yes] http://localhost:$PUERTO ./" | \\
       sudo tee /etc/apt/sources.list.d/telemetria-local.list
     sudo apt update

3) Instalar o revertir una version concreta:
     apt-cache policy telemetria
     sudo apt install telemetria             # ultima publicada
     sudo apt install telemetria=0.1.0       # version anterior (rollback)

Nota: [trusted=yes] evita firmar el repositorio y solo es aceptable en un
entorno de laboratorio. En produccion se firma el fichero Release con GPG
(InRelease) y los clientes verifican la firma.
INSTRUCCIONES
