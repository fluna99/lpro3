#!/usr/bin/env python3
"""Tarea 7 - Genera un SBOM (CycloneDX 1.6) del proyecto.

Un SBOM es el inventario de componentes de un producto software. Deja de ser
buena practica para ser obligacion legal: el Reglamento (UE) 2024/2847
(Cyber Resilience Act) exige a los fabricantes documentar los componentes de
sus productos con elementos digitales en un formato legible por maquina.

Uso: python3 scripts/40-generar-sbom.py [-s salida.json]
"""
import argparse
import datetime as dt
import json
import pathlib
import subprocess
import uuid

RAIZ = pathlib.Path(__file__).resolve().parent.parent


def version_del_proyecto() -> str:
    try:
        salida = subprocess.run(
            ["git", "describe", "--tags", "--always", "--match", "v[0-9]*"],
            cwd=RAIZ, capture_output=True, text=True, check=True)
        return salida.stdout.strip().lstrip("v")
    except (subprocess.CalledProcessError, FileNotFoundError):
        return (RAIZ / "VERSION").read_text(encoding="utf-8").strip()


def componente(dep: dict) -> dict:
    return {
        "type": "library",
        "bom-ref": f"pkg:generic/{dep['nombre']}@{dep['version']}",
        "name": dep["nombre"],
        "version": dep["version"],
        "scope": "required" if dep.get("ambito") == "requerido" else "optional",
        "licenses": [{"license": {"id": dep["licencia"]}}],
        "externalReferences": [{"type": "vcs", "url": dep["url"]}],
        "properties": [
            {"name": "telemetria:origen", "value": dep.get("origen", "desconocido")},
            {"name": "telemetria:responsable", "value": dep.get("responsable", "")},
        ],
    }


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("-s", "--salida", default=str(RAIZ / "build" / "informes" / "sbom.json"))
    args = ap.parse_args()

    manifiesto = json.loads((RAIZ / "dependencias.json").read_text(encoding="utf-8"))
    version = version_del_proyecto()

    sbom = {
        "bomFormat": "CycloneDX",
        "specVersion": "1.6",
        "serialNumber": f"urn:uuid:{uuid.uuid4()}",
        "version": 1,
        "metadata": {
            "timestamp": dt.datetime.now(dt.timezone.utc).isoformat(),
            "tools": {"components": [
                {"type": "application", "name": "40-generar-sbom.py", "version": "1.0"}]},
            "component": {
                "type": "application",
                "bom-ref": f"pkg:generic/telemetria@{version}",
                "name": manifiesto["proyecto"],
                "version": version,
                "licenses": [{"license": {"id": "MIT"}}],
            },
            "supplier": {"name": "ETSI Telecomunicacion - Universidad de Malaga"},
        },
        "components": [componente(d) for d in manifiesto["dependencias"]],
    }

    destino = pathlib.Path(args.salida)
    destino.parent.mkdir(parents=True, exist_ok=True)
    destino.write_text(json.dumps(sbom, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"SBOM generado: {destino}")
    print(f"  producto     : {manifiesto['proyecto']} {version}")
    print(f"  componentes  : {len(sbom['components'])}")
    for c in sbom["components"]:
        print(f"    - {c['name']} {c['version']} ({c['licenses'][0]['license']['id']})")


if __name__ == "__main__":
    main()
