# Datos semilla

`datos-iniciales-v0.1.sql` carga datos curriculares versionados y fixtures sintéticos. Se genera con `generar_semilla.py` desde el catálogo y el archivo de relaciones conservados en `referencias/curriculo/matematicas/2eso/`:

```sh
python3 base-de-datos/postgresql/semillas/generar_semilla.py
```

El generador comprueba que el ID, la versión y el SHA-256 del catálogo coincidan con la referencia del archivo de relaciones antes de producir SQL. Se incluyen 19 dominios, 308 objetivos y 451 relaciones candidatas. Estas relaciones mantienen su estado propuesto/no canónico. También se crea un alumno, profesor, sesión y clip ficticios para revisar importación y consultas. No se leen ni copian `datos-privados/`, el archivo SQLite, transcripciones o medios.
