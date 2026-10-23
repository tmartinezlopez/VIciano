# Relaciones y cardinalidades: borrador para revisión

**Estado:** propuesta inicial basada en el brief; no es DDL ni fija aún las relaciones finales.  
**Propósito:** separar los requisitos explícitos de las cardinalidades que falta confirmar antes de preparar PostgreSQL.

## Requisitos y hechos establecidos hasta ahora

- Alumno y Profesor son entidades estables, seleccionadas desde el sistema. La sesión debe asociarse mediante sus IDs; la cantidad de alumnos por sesión sigue abierta. Como hipótesis de trabajo, se considera un profesor por sesión.
- La sesión también se asocia al curso/asignatura y conserva el manifest completo vigente como entrada JSONB; si cambia, se reemplaza y se reindexa con el mismo ID. No se guardarán snapshots anteriores en esta entrega.
- La sesión grabada es distinta del contenido curricular (lección/tema); una sesión puede abarcar una o varias unidades curriculares.
- El flujo futuro de checklist tiene dos capas: contenidos curriculares y learning targets transversales. La IA propone nivel de apoyo y evidencias; el profesor confirma o corrige. Su formato y sus datos concretos todavía no están definidos.
- La información validada se consolida en un estado pedagógico cronológico. Su representación concreta se definirá junto con el formato de la checklist.
- En el modelo compartido, un clip puede vincularse a la sesión de la que procede. La exportación actual incluye metadatos por clip, pero no una URL de YouTube.

## Relaciones candidatas

| Relación | Propuesta inicial | Base | Qué falta confirmar |
|---|---|---|---|
| Alumno — Sesión | Una sesión se vincula al alumno o alumnos elegidos mediante sus IDs estables. | El brief exige seleccionar un alumno desde el sistema. | No está confirmado si una clase puede incluir a más de un alumno. Mantenerlo abierto; el ejemplo actual no resuelve esta cardinalidad. |
| Profesor — Sesión | Hipótesis de trabajo: un profesor seleccionado por sesión; un profesor puede asociarse a muchas sesiones. | El brief exige seleccionar al profesor desde el sistema. Tomás considera muy improbable que haya varios profesores en una sesión. | Tratar un profesor por sesión como supuesto provisional. Reabrirlo solo si Nacho o el flujo real muestran una excepción. |
| Curso/asignatura — Sesión | La sesión tiene contexto de curso y asignatura, y el modelo debe permitir añadir más contexto si el proyecto lo necesita. | El brief pide asociar curso/asignatura a la sesión y usarlos para contextualizar el currículo. | Decidir si curso y asignatura son entidades separadas o una referencia combinada. No hace falta cerrar ahora otros campos de contexto futuro. |
| Sesión — Lección curricular | Una sesión puede cubrir una o varias lecciones; una lección puede retomarse en distintas sesiones. Relación candidata de varios a varios. | El brief distingue clase concreta y contenido curricular. | Para la primera entrega no se guardarán intervalos de tiempo por lección: Tomás considera que añadirlos ahora sería sobreingeniería. Los tiempos de unidades pedagógicas siguen disponibles en los datos fuente; se podrá revisar esta necesidad más adelante. |
| Sesión — Manifest | La sesión conserva el manifest completo como entrada JSONB. Si se actualiza, se reemplaza el manifest vigente y se reindexan sus datos usando el mismo ID estable. | Requisito del brief de conservar el manifest; el ejemplo exportado incluye un manifest a nivel de exportación con siete unidades, además de un JSON separado por clip. | No se prevé guardar snapshots anteriores en la primera entrega. Revisitarlo solo si aparece el caso, considerado improbable, de reindexar un manifest con el mismo ID y se necesita rastrear versiones. La muestra no demuestra que su `lessonId` equivalga a una sesión. |
| Sesión — Clip | En el modelo compartido, una sesión puede originar cero o varios clips. La base compartida conservará metadatos útiles para consultar y relacionar el clip; los detalles operativos del render seguirán en App Clips. | En los archivos de ejemplo hay un JSON y un MP4 por clip. El JSON incluye tiempos, `fileName`, secuencia, unidades de origen, `renderOutputId`, versión y hash. | La exportación actual no contiene URL de YouTube. Tomás propuso esa URL como posibilidad posterior a una subida; no tratarla como dato disponible ni como requisito operativo actual. El subconjunto concreto de metadatos útiles se decidirá al revisar el ER. |
| Catálogo/version — Objetivo de aprendizaje | Un catálogo/version agrupa muchos objetivos; cada objetivo pertenece a una versión o conserva una referencia inequívoca a ella. | El JSON de 2.º tiene `catalog_id`, versión, dominios y objetivos. | Cómo conservar IDs estables cuando los catálogos evolucionen y se incorporen otras asignaturas/cursos. |
| Objetivo — Relación entre objetivos | Cada relación enlaza dos objetivos con dirección, tipo, estado y justificación. | El archivo de relaciones tiene objetivo origen, tipo y objetivo destino. | Vocabulario canónico, gobierno y paso de propuesta a relación aceptada. |
| Sesión — Checklist futura | La estructura debe permitir que de una sesión se prepare una checklist revisable por un profesor. | El brief define el flujo y sus dos capas, no el formulario final. | No fijar ahora si será una plantilla fija, preguntas condicionales o preguntas generadas a partir de la sesión; tampoco fijar entidades, campos o estados de respuesta. |
| Propuesta — Revisión humana — Estado validado | El modelo debe poder representar el flujo desde una propuesta de IA hasta información confirmada o corregida y su uso en el seguimiento cronológico. | Flujo descrito en el brief. | Dejar para el diseño conjunto de la checklist cómo se representan ítems, evidencias, correcciones, autoría, estados e historial. No anticipar su estructura en esta matriz. |

## Punto que necesita criterio pedagógico

El brief proporciona el flujo general, pero no define la checklist final. La base debe poder alojar el resultado de ese flujo; esta matriz no decide si las preguntas serán fijas, condicionales o generadas, ni propone campos o estados. Esas decisiones se tomarán con Nacho y los profesores; después Luis podrá validar su traducción a tablas e integridad relacional.

## Alcance de esta revisión

La propuesta se limita a relaciones necesarias para entender el modelo compartido y el estado pedagógico. Trabajos de procesamiento, eventos técnicos, exclusiones audiovisuales y parámetros de render de la SQLite se evaluarán aparte para decidir si forman parte de la base pedagógica común o siguen en App Clips.

La propuesta de entidades y relaciones está en el [esqueleto ER v0.1](esqueleto-er-v0.1.md); ya existe un DDL PostgreSQL v0.1 para revisión. Las cardinalidades provisionales se confirmarán con Luis/Nacho antes de tratar el esquema como definitivo.
