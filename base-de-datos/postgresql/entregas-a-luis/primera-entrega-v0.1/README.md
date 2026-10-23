# Primera entrega técnica para Luis · v0.1

Paquete autocontenido con el esquema PostgreSQL inicial y datos de muestra. Se preparó para PostgreSQL 16 o posterior; se probó en PostgreSQL 16. No requiere extensiones ni conexión a red.

## Contenido

- `esquema.sql`: crea el esquema `pedagogia` y sus tablas, restricciones e índices.
- `datos-iniciales.sql`: carga el catálogo experimental de Matemáticas de 2.º ESO, sus relaciones candidatas y una sesión/clip completamente ficticios.
- `SHA256SUMS`: huellas para comprobar que los archivos no cambiaron.

## Importar en una base vacía

```sh
createdb nombre_base
psql -v ON_ERROR_STOP=1 -d nombre_base -f esquema.sql
psql -v ON_ERROR_STOP=1 -d nombre_base -f datos-iniciales.sql
```

La semilla se puede ejecutar de nuevo para actualizar el catálogo de esa misma versión y restablecer los datos ficticios. No modifica registros reales. Para cargar otra versión del catálogo, genera una nueva versión del artefacto y revisa sus IDs antes de importarla.

## Comprobación rápida

```sql
SELECT count(*) FROM pedagogia.dominio_objetivo;              -- 19
SELECT count(*) FROM pedagogia.entrada_catalogo_objetivo;      -- 308
SELECT count(*) FROM pedagogia.relacion_objetivos;             -- 451
SELECT count(*) FROM pedagogia.sesion;                         -- 1 fixture
SELECT count(*) FROM pedagogia.clip;                           -- 1 fixture
```

Las 451 relaciones conservan `PROPOSED` y `es_canonica = false`; no se han tratado como relaciones aprobadas. El catálogo se declara experimental e incompleto. La semilla no incorpora la SQLite, transcripciones, vídeo ni registros reales.

## Límites acordados

La primera versión supone un alumno y un profesor por sesión. Mantiene un solo manifest vigente por sesión y no almacena snapshots anteriores. La URL de YouTube no está incluida. No se incluyen tablas de checklist, propuestas de IA, estado pedagógico validado ni atributos derivados con prompts; esos campos se diseñarán después de acordar el flujo con Nacho/Luis.

## Revisión solicitada

Después de importar el paquete, informa de cualquier error o ajuste necesario y revisa las claves, cardinalidades, restricciones e índices. Confirma también si la estructura deja claro dónde se reciben el manifest y los IDs estables de alumno y profesor. El [informe de entrega](../../../../documentacion/entregas/primera-entrega-v0.1/informe-de-entrega.md) reúne estos puntos y distingue los asuntos que debe precisar Nacho sobre el flujo de App Clips.
