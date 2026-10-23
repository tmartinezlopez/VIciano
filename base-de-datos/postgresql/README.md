# PostgreSQL

La migración versionada es la fuente del esquema. `semillas/` contiene datos públicos del catálogo y fixtures ficticios; `entregas-a-luis/` contiene copias autocontenidas y comprobables para entregar.

Para importar la versión de trabajo en una base vacía:

```sh
psql -v ON_ERROR_STOP=1 -d nombre_base -f migraciones/001_esqueleto_compartido_v0_1.sql
psql -v ON_ERROR_STOP=1 -d nombre_base -f semillas/datos-iniciales-v0.1.sql
```

La primera importación verificada usa PostgreSQL 16. El esquema está en `pedagogia`. El catálogo se carga con sus versiones y estados de origen; las 451 relaciones permanecen propuestas y no canónicas. Las personas y la sesión de muestra son ficticias. No se incluyen datos privados.
