# Esqueleto inicial del modelo de datos

**Fecha:** 2026-10-10  
**Estado:** decisiones de alcance acordadas; cardinalidades y estructura ER en revisión.

## Contexto

Se está preparando el primer modelo relacional compartido a partir del brief, la SQLite operativa de App Clips, la exportación de ejemplo y las fuentes curriculares disponibles. La primera versión debe ser útil sin adelantar el diseño de la checklist ni replicar todo el pipeline operativo.

## Decisiones acordadas para la primera entrega

1. No se guardarán intervalos de tiempo que vinculen una unidad curricular con un tramo de la sesión. Podrá revisarse en el futuro si aparece un caso de uso claro.
2. Cada sesión mantendrá un manifest completo vigente en JSONB. Si cambia, se reemplazará y se reindexará usando el mismo ID. No se guardarán snapshots previos en esta primera versión. Se reconsiderará si hace falta rastrear una reindexación del mismo ID.
3. La base compartida conservará metadatos de clip útiles para consulta y relación. Los detalles técnicos del render permanecerán en App Clips. La URL de YouTube no se considera un dato actual.
4. El esqueleto de datos precede al tratamiento de campos con prompts. La generación de atributos derivados —incluidos los que luego alimenten checklists— pertenece a una fase posterior y no se modela todavía.

## Supuestos del borrador, pendientes de revisión

- Una sesión tiene un alumno y un profesor. El flujo del brief selecciona un alumno y un profesor; la posibilidad de clases grupales sigue sin confirmarse.
- Curso y asignatura se proponen como entidades separadas y vinculadas mediante una asociación, para mantener el contexto educativo reutilizable.
- La fuente `Lesson` de App Clips no se equipara todavía a Sesión ni a Lección curricular. Se conservará su referencia de origen hasta acordar el mapeo.
- La identidad estable de los learning targets se separará de las entradas y etiquetas específicas de cada versión de catálogo. La política concreta se revisará con quienes gobiernen los catálogos.
- El ER muestra por ahora dos tipos conceptuales de estado pedagógico validado, uno por capa (curricular y learning target), para reflejar el seguimiento cronológico. Si compartirán una estructura o tabla queda pendiente hasta concretar la checklist.

## Consecuencias

El documento [esqueleto ER v0.1](../modelo-de-datos/esqueleto-er-v0.1.md) propone entidades y relaciones sobre estas bases. El [DDL PostgreSQL v0.1](../../../base-de-datos/postgresql/migraciones/001_esqueleto_compartido_v0_1.sql) implementa el núcleo revisable. Se revisarán con Luis las cardinalidades provisionales, el mapeo de IDs de origen y el alcance de metadatos de clip. La checklist, su contenido, el estado pedagógico validado y los campos derivados por prompts se diseñarán después.
