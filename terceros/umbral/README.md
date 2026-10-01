# umbral

Biblioteca de ejemplo que hace de **dependencia externa** del proyecto
`telemetria` durante el taller.

Se aloja en su propio repositorio de GitHub (`EQUIPO/umbral`) y se etiqueta
como `v1.2.0`. El proyecto principal la consume con esa etiqueta exacta,
nunca con una rama móvil (`cmake/Dependencias.cmake`).

En la tarea 4 el equipo crea además una copia íntegra local
(`~/taller-infra/git/umbral.git`, mediante `git clone --mirror`) y ensaya
compilar contra ella en lugar de contra GitHub: es el procedimiento de
continuidad por si el servicio de alojamiento no estuviera disponible, no la
forma habitual de publicar la dependencia.
