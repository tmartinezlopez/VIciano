# Esqueleto entidad-relación v0.1

**Estado:** borrador lógico implementado como esquema PostgreSQL v0.1 para revisión. No fija los detalles de la checklist ni da por cerradas las cardinalidades provisionales.

Este esqueleto cubre personas, sesiones, contexto curricular, fuentes de entrada, unidades curriculares, catálogo de objetivos y clips. Mantiene separados los conceptos pedagógicos y las tablas operativas del pipeline de App Clips. El bloque de checklist y estados validados aparece como fase posterior y todavía no forma parte del DDL.

## Vista visual del modelo

![Diagrama visual del esqueleto del modelo, sus datos disponibles y las fases posteriores](diagrama-esqueleto-er-v0.1.png)

La lámina se organiza en tres partes del esquema actual: azul para clase y clips, verde para el contenido curricular y violeta para el catálogo de objetivos. La franja naranja muestra el flujo futuro de propuesta y revisión docente, todavía fuera del SQL v0.1; gris marca la futura consulta de Virtut. La etiqueta del catálogo se conserva por versión y se vincula a una identidad reutilizable del objetivo. La URL de YouTube aún no está disponible en el flujo actual. La tarjeta superior indica como supuesto revisable un alumno y un profesor por sesión.

La cardinalidad propuesta para la sesión es un alumno y un profesor, y un contexto de curso/asignatura. Son supuestos iniciales a partir del flujo del brief; se pueden revisar si el uso real muestra clases grupales u otras combinaciones.

## Responsabilidad de las entidades

| Entidad | Qué representa | Datos iniciales a contemplar |
|---|---|---|
| Alumno, Profesor | Personas con IDs estables del sistema. | ID interno y los atributos mínimos que se definan para identificarlos. No usar nombres, archivos ni voz como claves. |
| Curso, Asignatura, Curso_Asignatura | Contexto educativo de la sesión. Se proponen curso y asignatura separados y una asociación válida entre ambos. | IDs y etiquetas; el detalle de contexto adicional queda extensible. |
| Sesión | Clase concreta impartida/grabada. | IDs de alumno, profesor y curso/asignatura; manifest vigente completo en JSONB; referencia de origen externa sin asumir que `lessonId` significa sesión. |
| Versión_Fuente_Curricular, Unidad_Curricular | Fuente/versionado del currículo y sus unidades de contenido, potencialmente jerárquicas. | Referencia a curso/asignatura, fuente, versión, ID de origen, nombre y relación padre-hijo. No se guardan tiempos de la sesión por unidad en esta entrega. |
| Sesión_Unidad_Curricular | Asociación entre sesiones y las unidades curriculares que trabajan. | IDs de sesión y unidad. Relación muchos a muchos, sin intervalos temporales. |
| Estado_Curricular_Validado, Estado_Objetivo_Validado (fase posterior) | Conceptos de seguimiento cronológico de resultados confirmados por el profesor en las dos capas pedagógicas. | Se muestran para explicar el objetivo del flujo, pero no tienen tablas en el DDL v0.1. La checklist definirá los campos, evidencias, revisiones e historial. |
| Clip | Segmento útil derivado de una sesión. | ID de origen, inicio/fin, título, tema, objetivo y nombre de archivo cuando sean útiles para consulta y referencia. El detalle técnico del render permanece en App Clips; no se contempla una URL de YouTube actual. |
| Versión_Catálogo_Objetivos, Dominio_Objetivo, Entrada_Catálogo_Objetivo, Objetivo_Aprendizaje | Catálogos versionados y la identidad de los objetivos que cada versión describe. | La entrada de catálogo permite conservar etiquetas/IDs de origen por versión y vincularlas a una identidad estable de objetivo. Esta separación es una propuesta para que la evolución del catálogo no dependa de sus etiquetas; debe revisarse al definir su gobierno. |
| Relación_Objetivos | Relación dirigida entre dos objetivos de aprendizaje. | Objetivo origen/destino, tipo y estado (por ejemplo, propuesta o aceptada), además de procedencia/justificación según los datos aprobados. |

## Decisiones ya aplicadas

- Una sesión puede asociarse con una o varias unidades curriculares, pero en esta entrega no se registra el minuto de la grabación correspondiente a cada unidad.
- La sesión mantiene un solo manifest vigente. Si cambia, se reemplaza y se reindexa con el mismo ID; no se guardan snapshots previos en esta primera versión.
- La base compartida conserva metadatos de clip útiles para consulta. Los parámetros y resultados operativos del render siguen en App Clips.
- El manifest de ejemplo es por exportación y cada clip tiene su propio JSON; no se infiere que el `lessonId` de origen equivalga a una sesión.

## Fases posteriores, fuera de este esqueleto

El flujo de checklist —propuesta de IA, revisión/corrección docente y estado pedagógico validado— se apoya en la sesión, el currículo y el catálogo de objetivos. El diagrama incluye registros cronológicos conceptuales para los resultados validados de las dos capas. Sus campos, el formato de checklist y si los dos tipos comparten tabla se revisarán en una fase posterior; no se fijan preguntas ni estados de respuesta en el DDL v0.1.

Después de cerrar el esqueleto se abordará el tratamiento de campos de entrada con prompts para generar datos derivados reutilizables, incluida información que pueda servir para las checklists. Esa fase deberá distinguir los datos fuente de los derivados y conservar su procedencia; todavía no se añaden entidades ni campos para ese proceso.

## Alcance de la implementación PostgreSQL v0.1

El DDL incluye personas, curso/asignatura, sesión con manifest JSONB vigente, clips, estructura para fuentes/unidades curriculares y el catálogo versionado con sus dominios, objetivos y relaciones. La semilla carga el catálogo experimental de 2.º ESO, sus 19 dominios, 308 objetivos y 451 relaciones candidatas, conservando su estado no canónico. Añade una sesión y un clip totalmente ficticios para comprobar las relaciones.

La prueba no carga unidades curriculares: el catálogo JSON disponible enumera objetivos, no un temario estructurado. Tampoco crea tablas de checklist, propuestas, validación pedagógica o campos derivados con prompts. Esos campos dependen de decisiones que siguen abiertas y se definirán después.

## Pendientes que no bloquean el primer borrador

- Confirmar con Nacho/Luis cómo se mapea el `Lesson` de App Clips a sesión y contenido curricular.
- Confirmar si en algún uso una sesión puede incluir a varios alumnos; el primer borrador asume uno.
- Revisar si curso y asignatura deben ser entidades separadas, como aquí se propone.
- Definir con los responsables curriculares la identidad estable de los objetivos y la evolución entre versiones del catálogo.
- Concretar los campos de la checklist y los registros de estado validado cuando se acuerde el flujo real.

Para revisar las relaciones y sus bases, consulta la [matriz de relaciones y cardinalidades](relaciones-y-cardinalidades-borrador.md) y la [propuesta conceptual](propuesta-modelo-conceptual-v0.1.md).
