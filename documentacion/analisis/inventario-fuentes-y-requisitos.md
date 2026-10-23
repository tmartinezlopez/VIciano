# Inventario de fuentes y requisitos

**Revisión:** 10 de octubre de 2026  
**Propósito:** dejar una base común de lo observado en las fuentes, lo que pide el brief y las decisiones que siguen abiertas. Este inventario describe las fuentes actuales; no define todavía el esquema PostgreSQL objetivo.

## Fuentes revisadas

| Fuente | Qué aporta | Alcance y cautelas |
|---|---|---|
| Brief operativo, PDF de 8 páginas en `documentacion/proyecto/briefs/` | Hito inicial: modelo entidad-relación y primera versión PostgreSQL importable por Luis; base pedagógica compartida iniciada por App Clips Classes, con Virtut como consumidor futuro conocido; conservación de la entrada, datos pedagógicos estructurados y validación humana. | Es la referencia de objetivos del proyecto. Tomás precisa que el modelo debe ser reutilizable para otros usos de datos e IA, no centrarse solo en Virtut. El PDF es confidencial y permanece excluido de Git. |
| SQLite `datos-privados/app-clips/origen/dev.db` | Snapshot del pipeline actual de App Clips: análisis audiovisual y pedagógico, transcripciones, clips, revisiones, procesado y exportaciones. | Se leyó en modo de solo lectura. Es una fuente del sistema actual, no el modelo compartido que hay que diseñar. No fue necesario restaurarla para inspeccionarla como SQLite. |
| Exportación `lesson-export-v1` | Un `manifest.json` a nivel de exportación con siete unidades pedagógicas, `export-metadata.json` y siete pares de JSON+MP4 (un JSON por clip). | No demuestra que `lessonId` equivalga a una sesión. Los JSON de clip incluyen tiempos, nombre del archivo, secuencia, unidades pedagógicas de origen y referencias/versiones/hash del render; no incluyen URL de YouTube. Tomás indica que la fidelidad de transcripciones y tiempos respecto a la grabación ya está corroborada. Los artefactos permanecen en `datos-privados/`. |
| Catálogo `referencias/curriculo/matematicas/2eso/catalogo-learning-targets/` | Catálogo experimental de Matemáticas de 2.º ESO: 308 objetivos en 19 dominios, versión 0.1, marcado `VALIDATED_FOR_EXPERIMENT`; declara que no pretende ser completo. | Sus relaciones asociadas son 451 propuestas no canónicas que requieren revisión humana. No deben tratarse como relaciones curriculares aprobadas. |
| Índice de Matemáticas de 3.º ESO y análisis histórico de andamiajes | Aportan otro ejemplo curricular y un análisis previo basado en el índice de 3.º. | Según Tomás, los ejemplos de 2.º y 3.º fueron aportados por Nacho para un proyecto que cubrirá varios cursos. No son una discrepancia ni limitan el alcance a esos dos cursos. La estructura curricular de los demás cursos se definirá o incorporará más adelante. |
| Libro de Matemáticas de 2.º ESO, conservado localmente | Fuente de apoyo del catálogo experimental de 2.º. | Se mantiene local y excluido de Git mientras no se determine si puede compartirse. |

### Estructura de la exportación de ejemplo

- `export-metadata.json`: `lessonId`, `exportedAt`, `clipCount`, `version`, `renderVersions`.
- `manifest.json`: `lessonId`, `transcriptId`, `transcriptVersion`, `pedagogicalAnalysisId`, `pedagogicalAnalysisVersion`, `pedagogicalUnits`. Cada unidad contiene ID, secuencia y tiempos, título/tema/objetivo, justificación, frases de inicio y fin, puntuaciones, metodología y listas JSON de pasos, conceptos, ejercicios, errores, correcciones, conocimientos previos e interacciones.
- Cada uno de los siete JSON de clip: `schemaVersion`, `clipId`, `lessonId`, `fileName`, `exportSequence`, título y duración/tiempos, tema, objetivo, justificación, confianza/calidad, `fusionRunId`, `sourcePedagogicalUnitIds`, metodología y datos pedagógicos estructurados, `renderOutputId`, `renderVersion` y `outputHash`.
- Los `fileName` de los JSON corresponden a los MP4 entregados. En este ejemplo, `lessonId`, análisis, unidades y clips enlazan con sus registros de SQLite. La exportación es una muestra concreta del formato, no una especificación completa de la futura ingesta.

El catálogo de 2.º declara `catalog_id`, versión, estado, fecha del snapshot, alcance, propósito, afirmación de completitud, gobernanza, fuentes, linaje histórico, resumen de validación y dominios con objetivos. El archivo de relaciones incluye ID de relación, objetivo origen/destino, tipo, estado, condición canónica, requisito de revisión, prioridad, justificación y notas. Sus 451 relaciones están propuestas y no canónicas.

## Modelo que existe en la SQLite

La base contiene 18 tablas de aplicación y `_prisma_migrations` (28 filas). Los nombres siguientes son los del origen. Los campos resumidos son los más relevantes para entender su función; la lista no propone conservarlos todos en el destino.

| Tabla (filas) | Datos observados y relaciones declaradas |
|---|---|
| `Lesson` (144) | Estado y estado anterior; `teacherId` y `visualProfileId` opcionales. Referencia a `Teacher` y `VisualProfile`. |
| `Teacher` (5) | Identificador, nombre y fechas; se referencia desde `Lesson` y `VisualProfile`. |
| `VisualProfile` (7) | Profesor, versión y parámetros de recorte, encuadre y salida. Referencia a `Teacher`. |
| `MediaAsset` (266) | Lección, tipo, MIME, ruta, hash, tamaño, duración, códec y dimensiones. Referencia a `Lesson`. |
| `Transcript` (128) | Lección, proveedor/modelo, idioma, confianza, versión, estado, texto completo, duración y hashes. Referencia a `Lesson`. |
| `TranscriptUtterance` (26.843) | Transcripción, hablante, secuencia, inicio/fin, confianza y texto. Referencia a `Transcript`. |
| `PedagogicalAnalysis` (127) | Transcripción, prompt/modelo y versiones, hashes, consumo, latencia, estado. Referencia a `Transcript`. |
| `PedagogicalUnit` (570) | Análisis, secuencia, tiempos, título, tema, objetivo, justificación, puntuaciones y contenido estructurado en JSON (pasos, conceptos, ejercicios, errores, correcciones, conocimientos previos e interacciones). Referencia a `PedagogicalAnalysis`. |
| `AudiovisualAnalysis` (124) | Recurso audiovisual, versiones de algoritmo/configuración, hashes, versión y estado. Referencia a `MediaAsset`. |
| `ExclusionInterval` (152.654) | Análisis audiovisual, tipo, intervalo, severidad, confianza, motivo y metadatos JSON. Referencia a `AudiovisualAnalysis`. |
| `FusionRun` (125) | Análisis pedagógico y audiovisual, versiones de estrategia/política, hashes, versión y estado. Referencia a ambos análisis. |
| `Clip` (533) | Lección y fusión; tiempos, título, tema, objetivo, justificación, confianza, `qualityScore`, estado y lista JSON de unidades de origen. Referencia a `Lesson` y `FusionRun`; los IDs de unidades en JSON no tienen FK declarada. |
| `ClipReview` (566) | Clip, acción, tiempos anteriores/nuevos, categoría de feedback, notas y fechas. Referencia a `Clip`; no incluye identificador de quien revisó. |
| `ClipSegment` (533) | Clip, secuencia y tiempos. Referencia a `Clip`. |
| `RenderOutput` (554) | Clip, versión/estado de render, formato, duración/tamaño, ruta, hashes y parámetros de perfil/recorte. Referencia a `Clip`. |
| `LessonExport` (123) | Lección, versión, nombre/estado del archivo, ruta, tamaño, caducidad y hashes. Referencia a `Lesson`. |
| `ProcessingJob` (1.139) | Lección, tipo/estado/intento, correlación, idempotencia, trabajador, tiempos y errores. Referencia a `Lesson`; `idempotencyKey` tiene índice único. |
| `DomainEventRecord` (2.173) | Tipo/versionado de evento, agregado, correlación/causalidad y payload JSON. `aggregateId` es genérico y no tiene FK declarada. |

Las relaciones declaradas describen el flujo operativo `Lesson` → recursos/transcripción → análisis → unidades/fusión → clips → revisiones, segmentos y renders. También hay exportaciones y trabajos asociados a la lección. No hay entidades de curso, asignatura, currículo, objetivo de aprendizaje canónico o estudiante, ni un registro explícito que capture un proceso completo de validación pedagógica. Esto describe la SQLite actual, no afirma que todas esas piezas deban aparecer en la primera versión compartida.

### Nombres exactos de las columnas

Se conservan los nombres originales para facilitar su cotejo con SQLite. Los campos JSON se indican como columnas, sin reproducir aquí sus valores.

| Tabla | Columnas del origen |
|---|---|
| `Lesson` | `id`, `teacherId`, `visualProfileId`, `status`, `previousStatus`, `createdAt`, `updatedAt` |
| `Teacher` | `id`, `name`, `createdAt`, `updatedAt` |
| `VisualProfile` | `id`, `teacherId`, `cropX`, `cropY`, `cropWidth`, `cropHeight`, `sourceWidth`, `sourceHeight`, `outputWidth`, `outputHeight`, `fitMode`, `paddingMode`, `version`, `createdAt`, `updatedAt` |
| `MediaAsset` | `id`, `lessonId`, `assetType`, `mimeType`, `storagePath`, `hash`, `fileSize`, `durationSeconds`, `codec`, `width`, `height`, `createdAt`, `updatedAt` |
| `Transcript` | `id`, `lessonId`, `provider`, `model`, `language`, `confidence`, `inputHash`, `outputHash`, `version`, `status`, `fullText`, `durationMs`, `createdAt`, `updatedAt` |
| `TranscriptUtterance` | `id`, `transcriptId`, `speaker`, `start`, `end`, `sequence`, `confidence`, `text`, `createdAt`, `updatedAt` |
| `PedagogicalAnalysis` | `id`, `transcriptId`, `promptVersion`, `model`, `inputHash`, `outputHash`, `promptTokens`, `completionTokens`, `estimatedCost`, `latencyMs`, `completionReason`, `version`, `status`, `createdAt`, `updatedAt` |
| `PedagogicalUnit` | `id`, `pedagogicalAnalysisId`, `sequence`, `startSeconds`, `endSeconds`, `suggestedTitle`, `mainTopic`, `learningObjective`, `justification`, `suggestedOpeningPhrase`, `suggestedEndingPhrase`, `confidenceScore`, `pedagogicalScore`, `resolutionMethodology`, `steps`, `concepts`, `exercises`, `studentErrors`, `teacherCorrections`, `priorKnowledge`, `createdAt`, `updatedAt`, `pedagogicalInteractions` |
| `AudiovisualAnalysis` | `id`, `mediaAssetId`, `algorithmVersion`, `configurationVersion`, `inputHash`, `outputHash`, `version`, `status`, `createdAt`, `updatedAt` |
| `ExclusionInterval` | `id`, `audiovisualAnalysisId`, `intervalType`, `startSeconds`, `endSeconds`, `severity`, `confidence`, `reason`, `metadata`, `createdAt`, `updatedAt` |
| `FusionRun` | `id`, `pedagogicalAnalysisId`, `audiovisualAnalysisId`, `strategyVersion`, `policyVersion`, `inputHash`, `outputHash`, `version`, `status`, `createdAt`, `updatedAt` |
| `Clip` | `id`, `lessonId`, `fusionRunId`, `startSeconds`, `endSeconds`, `suggestedTitle`, `mainTopic`, `learningObjective`, `pedagogicalJustification`, `confidenceScore`, `qualityScore`, `currentTitle`, `status`, `approvedAt`, `rejectedAt`, `createdAt`, `updatedAt`, `sourcePedagogicalUnitIds` |
| `ClipReview` | `id`, `clipId`, `action`, `previousStartSeconds`, `previousEndSeconds`, `newStartSeconds`, `newEndSeconds`, `feedbackCategory`, `notes`, `createdAt`, `updatedAt` |
| `ClipSegment` | `id`, `clipId`, `sequence`, `startSeconds`, `endSeconds`, `createdAt`, `updatedAt` |
| `RenderOutput` | `id`, `clipId`, `renderVersion`, `status`, `width`, `height`, `codec`, `crf`, `duration`, `fileSize`, `storagePath`, `inputHash`, `outputHash`, `finishedAt`, `snapshotProfileId`, `snapshotProfileVersion`, `snapshotCropX`, `snapshotCropY`, `snapshotCropWidth`, `snapshotCropHeight`, `snapshotSourceWidth`, `snapshotSourceHeight`, `snapshotOutputWidth`, `snapshotOutputHeight`, `snapshotFitMode`, `snapshotPaddingMode`, `createdAt`, `updatedAt` |
| `LessonExport` | `id`, `lessonId`, `version`, `fileName`, `status`, `storagePath`, `fileSize`, `expiresAt`, `inputHash`, `outputHash`, `createdAt`, `updatedAt` |
| `ProcessingJob` | `id`, `lessonId`, `jobType`, `status`, `attempt`, `correlationId`, `causationId`, `idempotencyKey`, `workerId`, `leaseExpiresAt`, `lastHeartbeatAt`, `startedAt`, `finishedAt`, `createdAt`, `updatedAt`, `errorCode`, `errorContext`, `errorMessage`, `availableAt` |
| `DomainEventRecord` | `id`, `aggregateId`, `aggregateType`, `eventType`, `version`, `occurredAt`, `correlationId`, `causationId`, `payload`, `createdAt`, `updatedAt` |
| `_prisma_migrations` | `id`, `checksum`, `finished_at`, `migration_name`, `logs`, `rolled_back_at`, `started_at`, `applied_steps_count` |

## Comparación con el brief

| Necesidad del brief | Evidencia actual | Lectura para el modelo compartido |
|---|---|---|
| Compartir datos entre App Clips y Virtut | La SQLite cubre el pipeline de App Clips; no contiene el esquema compartido ni un contrato de consulta de Virtut. | Diseñar el modelo objetivo aparte y dejar su contrato de consumo para el hito correspondiente. |
| Conservar la entrada y rastrear su procesamiento | El brief acuerda guardar el manifest completo de cada sesión como JSONB/histórico; el ejemplo actual tiene un manifest por exportación y un JSON por clip. SQLite conserva hashes y versiones de análisis/modelos/estrategias. | Primera entrega: mantener el manifest vigente por sesión y reindexar al actualizarlo; no guardar snapshots previos. Reconsiderar solo si se necesita rastrear una reindexación del mismo ID. No confundir el versionado del manifest con las versiones de análisis/modelos. |
| Estructurar información pedagógica | Existen unidades, objetivos, temas, pasos y otros datos generados por análisis. | Separar datos fuente, propuestas de análisis y datos aceptados; no convertir automáticamente todo campo existente en dato canónico. |
| Incorporar currículo y objetivos de aprendizaje | Existe el catálogo experimental de 2.º y un índice de 3.º como ejemplo; no hay entidades curriculares en SQLite. | El alcance futuro es multigrado. El modelo debe identificar curso/asignatura y procedencia/versión según esté disponible; la representación común y los metadatos territoriales se definirán al incorporar más cursos. |
| Alumno y profesor como entidades estables | La SQLite tiene `Teacher`, pero no `Student`; el brief exige ambas entidades y que se seleccionen desde el sistema. | Incluir ambas en el modelo objetivo. El contrato de ingesta debe definir cómo llegan sus IDs y cómo se vinculan con sesión, curso/asignatura y manifest. |
| Validación humana | El brief define dos capas de checklist, propuesta de IA, confirmación/corrección del profesor y consolidación del resultado validado. En SQLite hay `ClipReview`, pero no es prueba de que represente ese flujo pedagógico. | El flujo general es requisito; faltan el formato exacto, los campos/estados de la checklist y su correspondencia con las tablas actuales. |
| Consulta limitada de Virtut | No hay contrato de consulta ni esquema de permisos implementado en las fuentes revisadas. | Mantenerlo como trabajo posterior, tal como prevé el brief. |
| Proteger datos educativos sensibles | La SQLite contiene texto de transcripción, nombres de profesores, rutas y datos de proceso. | Evitar copiar datos personales o texto de alumnos a documentación versionada; usar ejemplos sintéticos o sanitizados. |

## Decisiones abiertas, sin bloquear el inventario

1. **Lección y sesión.** El brief pide conceptos separados: lección como unidad de contenido y sesión como clase impartida/grabada; una sesión puede abarcar una o varias lecciones. Sigue pendiente mapear con precisión la tabla SQLite `Lesson` y cerrar las cardinalidades.
2. **Validación pedagógica.** El flujo general del brief está definido: la IA propone contenido/learning targets, nivel de apoyo y evidencias en dos capas; el profesor confirma o corrige; lo validado pasa a la capa relacional. Quedan abiertos el formato de checklist, sus campos/estados y cómo se registra cada corrección. La revisión operativa `ClipReview` no demuestra que ese flujo esté ya implementado.
3. **Catálogos multigrado.** Los ejemplos de 2.º y 3.º son compatibles con el alcance futuro. Queda por decidir cómo se identificarán y versionarán los currículos de cada curso y territorio a medida que se incorporen.
4. **Puntuaciones.** No se conoce el significado operativo de `qualityScore`, `pedagogicalScore` y `confidenceScore`; sus valores no se usarán como reglas pedagógicas hasta documentar su definición.
5. **Ingesta y consulta.** Concretar con Nacho la forma de entrada y, en la etapa prevista, acordar con Virtut la superficie de consulta y sus permisos.

## Uso de este documento

Este inventario es principalmente un documento interno de trabajo para Tomás y el desarrollo: conserva la lectura de las fuentes, evita repetir la inspección y permite separar hechos de decisiones. No es por sí mismo un entregable para Luis o Nacho; si una consulta con ellos resulta necesaria, se puede preparar un resumen acotado a esa pregunta. Las observaciones técnicas y cuantitativas están en la [revisión de la SQLite](revision-tecnica-completitud-sqlite.md). Las hipótesis anteriores solo se convertirán en decisiones de arquitectura cuando haya evidencia o acuerdo suficiente; hasta entonces deben mantenerse visibles como pendientes.
