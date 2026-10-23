# Borrador del modelo conceptual de datos

**Estado:** borrador para revisar con Tomás, Luis y Nacho. Actualizado el 10 de octubre de 2026. No es todavía un esquema PostgreSQL ni fija tablas y cardinalidades definitivas.

## Propósito del modelo

La prioridad es una base de datos clara, sólida, adaptable y reutilizable en proyectos de IA y otros usos futuros. El brief sitúa App Clips Classes como origen inicial de datos y Virtut como uno de sus posibles consumidores; el diseño no debe quedar condicionado a Virtut como único uso.

La base guardará el manifest completo de entrada y permitirá proyectar a relaciones normalizadas la información pedagógica que se valide. Si se actualiza, la hipótesis acordada es reemplazar el manifest vigente y reindexar sus datos con el mismo ID estable. La primera entrega no guardará snapshots anteriores; se reconsiderará si surge la necesidad de reindexar un manifest con el mismo ID y rastrear sus versiones. El formato y los datos operativos podrán evolucionar; cualquier cambio material de App Clips deberá coordinarse con Nacho.

## Mapa sencillo

```text
CATÁLOGOS Y CONTENIDOS
  Catálogo de objetivos de aprendizaje
    ├── reúne objetivos con ID estable
    └── puede contener relaciones propuestas entre objetivos
  Contexto: curso y asignatura; fuente y versión del catálogo

CLASE Y DATOS DE ENTRADA
  Profesor selecciona al alumno y al profesor desde el sistema
    └── se crea/asocia una sesión de clase a alumno, profesor y curso/asignatura
          ├── conserva el manifest vigente completo como entrada (JSONB; reemplazo y reindexación si cambia)
          ├── puede incluir transcripción, recursos y clips
          └── se analiza para preparar una checklist

CHECKLIST Y DATOS PEDAGÓGICOS
  IA propone contenidos/learning targets, evidencias y nivel de apoyo
    └── profesor confirma o corrige
          └── información validada pasa a la capa relacional e histórica

CONTENIDO Y EVENTO
  Lección curricular = contenido
  Sesión = clase concreta impartida/grabada
  Una sesión puede cubrir una o varias lecciones; la cardinalidad final se acuerda.
```

El brief establece las entidades Alumno y Profesor, la selección desde el sistema y la separación conceptual entre lección curricular y sesión grabada. El nombre definitivo de `Lesson` y las cardinalidades exactas siguen abiertos.

## Conceptos y procedencia

### Catálogo de objetivos de aprendizaje (Learning Target Catalog)

Sirve para agrupar objetivos dentro de un curso/asignatura y conservar la versión y procedencia de la fuente. No hay una tabla con ese nombre en la SQLite: el concepto se propone a partir del catálogo JSON de Matemáticas de 2.º ESO, que sí tiene `catalog_id`, `catalog_version`, `scope`, `frozen_snapshot_date`, dominios y objetivos. El índice de 3.º ESO es otra fuente curricular, no una instancia del mismo formato demostrada.

**Territorio y edición:** no se añaden como campos obligatorios. La Comunidad Valenciana figura en el índice de 3.º, pero no como campo común del catálogo de 2.º. El catálogo de 2.º declara versión y fecha de snapshot; no tiene un campo llamado «edición». Curso/asignatura, fuente y versión se conservarán según aparezcan en cada catálogo, y la estructura común se decidirá conforme se incorporen más cursos.

En el [esqueleto ER](esqueleto-er-v0.1.md) se propone separar la identidad interna estable de un learning target de su entrada y etiqueta dentro de cada versión del catálogo. Así, el mismo objetivo podría aparecer en versiones distintas sin que un cambio de etiqueta cambie su identidad. Es una propuesta pendiente de revisar con quienes gobiernen los catálogos.

### Objetivo de aprendizaje (Learning Target)

Microhabilidad evaluable con ID estable, etiqueta y dominio, tal como requiere el brief. El catálogo actual de 2.º ESO tiene 308 objetivos en 19 dominios y no se declara completo. Es una primera muestra; ampliar y validar los objetivos de más cursos y materias será trabajo pedagógico futuro.

### Relación entre objetivos (Target Relation)

Enlaza un objetivo de origen con otro de destino y guarda el tipo y la justificación. Por ejemplo, “A se apoya en B” o “A forma parte de B”. El archivo disponible contiene 451 propuestas no canónicas que requieren revisión; el modelo debe distinguirlas de relaciones aceptadas.

### Alumno (Student)

El brief lo establece como entidad estable, con código interno —no el nombre como clave—, asociada a sus sesiones y al estado pedagógico cronológico. No existe en la SQLite actual, así que procede del requisito del brief y no del esquema de origen. La necesidad de datos personales exige recoger solo los identificadores y atributos necesarios.

### Profesor (Teacher)

El brief también lo establece como entidad estable, asociada a sesiones y validaciones, y seleccionada desde el sistema. La SQLite tiene una tabla `Teacher` y un `Lesson.teacherId` opcional. El contrato con Nacho debe precisar cómo llegan los IDs de alumno y profesor a PostgreSQL: el brief plantea seleccionarlos desde entidades del sistema, no deducirlos del nombre del archivo ni de lo dicho en la grabación.

### Curso, asignatura y catálogo

El brief da curso/asignatura como contexto curricular y pone Matemáticas de 2.º ESO como ejemplo. El diseño futuro cubrirá más cursos y materias; no se debe limitar a los catálogos actuales. Queda pendiente acordar con Nacho el gobierno y la forma de incorporar nuevos índices/catálogos y con Luis cómo representarlos en el modelo importable.

### Lección curricular (Lesson) y sesión de clase (Session)

El brief pide mantenerlas separadas: la lección es una unidad de contenido asociada al índice o currículo; la sesión es la clase concreta impartida y grabada, asociada a alumno, profesor y manifest. Una sesión puede abarcar una o varias unidades curriculares. La cantidad de alumnos por sesión sigue abierta; se toma un profesor por sesión como hipótesis provisional. La tabla fuente `Lesson` no resuelve por sí sola la nomenclatura; hay que acordar cómo mapearla con Nacho. Se conserva esa distinción conceptual mientras no haya una razón para modificarla.

### Manifest de sesión

El brief acuerda guardar el manifest completo como JSONB, vinculado a la sesión. La muestra disponible tiene un `manifest.json` por exportación con siete unidades pedagógicas y un JSON aparte para cada clip; no demuestra que `lessonId` equivalga a una sesión. Si el manifest se actualiza, la primera entrega lo reemplazará y reindexará sus datos con el mismo ID. No se guardarán snapshots anteriores salvo que más adelante sea necesario rastrear una reindexación del mismo ID. El modelo relacional conservará los datos necesarios para consultas fiables y el estado pedagógico validado; no se presupone que el manifest de ejemplo sea el formato final.

## Checklist: de la propuesta de IA a los datos validados

El flujo general sí está definido en el brief:

1. **Capa longitudinal curricular:** la IA cruza el manifest con el índice/temario y propone qué contenidos se trabajaron, el nivel de apoyo detectado y las evidencias. El profesor confirma o corrige.
2. **Capa transversal de learning targets:** la IA cruza el manifest con el catálogo aprobado, propone las microhabilidades detectadas, el apoyo y sus evidencias. El profesor valida o corrige; los IDs estables permiten seguir la evolución cronológica.
3. **Consolidación:** lo confirmado o corregido se refleja en la capa relacional como estado pedagógico, con evidencia, sesión, objetivo/tema, fecha y trazabilidad de la entrada y la propuesta.

El brief menciona autonomía y niveles de apoyo ligero, moderado o intensivo como ejemplo. El formato exacto de la checklist, sus campos, estados y valores queda por cerrar con Luis/Nacho y los profesores. No se presupone que la tabla `ClipReview` actual represente este flujo.

## Tratamiento de datos con prompts: fase posterior

Más adelante se podrán tratar campos de entrada mediante prompts y producir campos derivados reutilizables, por ejemplo para alimentar checklists u otros usos. Este trabajo va después del esqueleto de la base. El diseño de esos procesos y campos queda fuera de esta versión; cuando se aborde, deberá distinguir las fuentes originales de los resultados derivados y registrar su procedencia.

## Otros datos derivados

- **Evidencia:** hecho observado en una sesión —por ejemplo, error, ayuda, corrección, intervención o respuesta— que justifica una valoración. Debe poder enlazarse con la fuente y el objetivo/contenido al que da soporte.
- **Clip y media:** segmento audiovisual derivado de una sesión, con tiempos, contenido y metadatos de archivo/render. En los ejemplos hay un JSON por clip con tiempos, `fileName`, unidades de origen, referencia al render, versión y hash; no aparece URL de YouTube. Tomás ha propuesto esa URL como posible dato futuro tras una subida, pero App Clips no parece generarla actualmente.
- **Ejecución de análisis (Analysis Run):** posible registro de una ejecución concreta, su entrada, versiones de prompt/modelo/estrategia, hashes y resultado. `AnalysisRun` no es una tabla actual; es una abstracción posible de `PedagogicalAnalysis`, `AudiovisualAnalysis` y `FusionRun`. Queda por decidir si conviene un concepto común o mantener los procesos separados.

## Decisiones pendientes para la revisión con Luis y Nacho

- Revisión del DDL PostgreSQL v0.1 con Luis: nombres, restricciones, cardinalidades provisionales e índices.
- Contrato de ingesta con Nacho: IDs seleccionados de alumno/profesor, asociación de sesión y curso/asignatura, claves y evolución del manifest.
- Forma común de incorporar cursos, asignaturas, índices curriculares y catálogos futuros; los ejemplos de 2.º y 3.º no limitan el alcance.
- Checklist concreta: campos, niveles de apoyo, estados y cómo registrar confirmaciones/correcciones del profesor.
- Qué datos operativos actuales de transcripción, análisis, render y clip se normalizan en la base compartida.

El acceso de Virtut se diseñará en una fase posterior y con alcance limitado. La base debe quedar bien estructurada para admitir ese uso y otros usos futuros sin hacer de la integración con Virtut el único criterio del diseño.

## Fuentes de apoyo

- [Brief operativo](../../proyecto/briefs/README.md)
- [Inventario de fuentes y requisitos](../../analisis/inventario-fuentes-y-requisitos.md)
- [Revisión técnica y de completitud de SQLite](../../analisis/revision-tecnica-completitud-sqlite.md)
