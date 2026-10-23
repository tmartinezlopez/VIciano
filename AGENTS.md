# Reglas del repositorio

## Objetivo

Este proyecto diseña una base de datos pedagógica clara, sólida, adaptable y reutilizable para App Clips Classes y futuros usos, incluidos proyectos de IA. El brief sitúa App Clips como origen inicial y Virtut como consumidor futuro conocido. El primer entregable es un modelo entidad-relación y una versión PostgreSQL importable por Luis; la integración de Virtut y sus permisos de consulta pertenecen a fases posteriores.

## Modelo y procedencia de los datos

- Mantén separadas la lección como contenido pedagógico y la sesión como clase grabada; una sesión puede cubrir una o varias lecciones. Consulta con Nacho o Luis cómo mapear la tabla fuente `Lesson` cuando afecte a ingesta o cardinalidades.
- Modela Alumno y Profesor como entidades estables, según el brief; usa IDs internos, nunca el nombre o el archivo como clave. Define con Nacho cómo llegan esos IDs a la ingesta; no los deduzcas del contenido de audio/vídeo.
- Conserva un manifest completo vigente por sesión en JSONB. Si se actualiza, reemplázalo y reindexa con el mismo ID; no guardes snapshots anteriores en la primera entrega. Reevalúa esta regla si surge la necesidad de rastrear una reindexación del mismo ID.
- Una inferencia de IA es una propuesta. El estado pedagógico fiable requiere validación humana, con evidencias, responsable y fecha.
- Respeta el estado y la versión de los catálogos. Las relaciones candidatas no pasan a canónicas sin revisión humana; no cambies IDs ni hashes de referencia en silencio.
- Trata `dev.db` como una fuente del pipeline actual de App Clips, no como el esquema objetivo compartido.

## Flujo de trabajo

- Lee los artefactos existentes antes de cambiar un contrato, catálogo o esquema. Conserva los originales y explica cualquier transformación.
- Versiona el DDL PostgreSQL mediante migraciones; prepara entregas reproducibles e importables. No inventes comandos de build de aplicación: el repositorio todavía no contiene una app. Ejecuta validaciones de base de datos cuando se soliciten y usa herramientas presentes en el proyecto.
- Registra decisiones acordadas y pendientes en `documentacion/arquitectura/decisiones/`. Añade a `APRENDIZAJES.md` los problemas y soluciones que puedan repetirse; promueve allí las reglas estables.

## Herramientas y privacidad

- Para trabajar con PDF, aplica la skill `pdf` si está disponible: extrae el texto, renderiza las páginas y revisa visualmente el documento cuando el formato importe. No sobrescribas la fuente; guarda temporales fuera del repositorio.
- Usa la skill adecuada para otros formatos cuando esté disponible y deja los artefactos fuente intactos.
- `datos-privados/` y los archivos locales excluidos por `.gitignore` pueden contener datos de menores, voz, vídeo o progreso educativo. No los añadas a Git ni los subas a servicios externos. Usa fixtures sintéticos o sanitizados en `ejemplos/`; no incluyas credenciales.
