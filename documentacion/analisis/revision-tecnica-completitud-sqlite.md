# Revisión técnica y de completitud de `dev.db`

**Fecha de revisión:** 10 de octubre de 2026  
**Alcance:** comprobaciones técnicas y descriptivas del snapshot local de App Clips. Es una línea base, no una certificación de corrección semántica ni de calidad pedagógica.

Esta revisión incluye consultas reales a la SQLite —integridad, claves foráneas, recuentos, estados y asociaciones—, pero no es una investigación bibliográfica o pedagógica, una auditoría de seguridad ni una evaluación de la validez de los objetivos curriculares. Tampoco comprueba si una inferencia concreta de IA es correcta. Para esas evaluaciones hacen falta criterios definidos y, en la parte pedagógica, revisión de especialistas.

## Método y alcance

Se abrió `datos-privados/app-clips/origen/dev.db` en modo de solo lectura. La SQLite era accesible directamente; no hizo falta restaurarla para inspeccionar su estructura. Se consultaron integridad, claves foráneas declaradas, tablas, recuentos, estados y presencia de relaciones. Los resultados de este informe son agregados: no se copian aquí transcripciones, nombres, identificadores de registros ni contenido de alumnos. La base y las exportaciones siguen excluidas de Git.

Tomás indica que la correspondencia de las transcripciones y de los tiempos de los clips con la grabación ya está corroborada. El manifest revisado enlaza con los mismos registros de la muestra exportada. Esta revisión registra esa corroboración y el cotejo estructural del ejemplo; no redefine el procedimiento que la estableció.

## Resultados

| Comprobación | Resultado | Interpretación prudente |
|---|---:|---|
| `PRAGMA integrity_check` | `ok` | No se detectó corrupción estructural de SQLite. |
| `PRAGMA foreign_key_check` | 0 infracciones | No se encontraron infracciones de las claves foráneas declaradas. No demuestra que todas las relaciones de negocio estén modeladas como FK ni que los datos sean semánticamente correctos. |
| JSON almacenado en campos JSON/JSONB | Valores presentes válidos en la revisión | No se observó JSON mal formado en los valores revisados. Esto no valida su significado ni su conformidad con un contrato. |
| Cobertura de transcripción | 16 de 144 `Lesson` no tienen fila en `Transcript` | Puede depender del estado del proceso. No se clasifica todavía como defecto. |
| Asociación de profesor | 25 de 144 `Lesson` tienen `teacherId` nulo | No se sabe si la asociación es obligatoria para todos los estados o exportaciones. |
| Análisis de transcripciones | 2 de 128 `Transcript` no tienen `PedagogicalAnalysis` asociado | Requiere revisar estados y reglas de proceso antes de considerarlo un fallo. |
| `Clip.qualityScore` | 532 de 533 valen 0; el restante es aproximadamente 0,2 | Su semántica no está documentada. No debe interpretarse como medida fiable de calidad. |
| Historial de revisión/render | 16 clips tienen más de un `RenderOutput`; 32 tienen más de un `ClipReview` | Puede representar versionado e iteraciones normales. No se considera duplicidad errónea sin conocer las reglas del pipeline. |

### Estados observados

- `Lesson`: 116 `COMPLETED`, 13 `UPLOADED`, 7 `AWAITING_REVIEW`, 5 `FUSING` y 3 `ANALYZING`.
- `Clip`: 518 `APPROVED`, 8 `PROPOSED` y 7 `REJECTED`.
- `ProcessingJob`: 1.104 `COMPLETED` y 35 `FAILED`.
- `RenderOutput`: 515 `COMPLETED` y 39 `FAILED`.
- `LessonExport`: 19 `AVAILABLE` y 104 `DELETED`.

Estos estados hacen especialmente importante desglosar las ausencias por estado y versión. Por sí solos no indican si una fila incompleta es esperada o requiere corrección.

## Lectura y límites

La base pasó las comprobaciones estructurales realizadas. Eso es distinto de confirmar que cada registro esté completo, que sus relaciones reflejen el proceso de negocio o que una propuesta de IA sea pedagógicamente válida. `Teacher`, `DomainEventRecord` y `_prisma_migrations` no tienen FK propia; `DomainEventRecord` usa un `aggregateId` genérico y `_prisma_migrations` es metadato de infraestructura. Por tanto, “cero infracciones” se refiere exclusivamente a las restricciones definidas en el esquema.

La tabla `ClipReview` registra acción, cambios de tiempo, categoría y notas, pero no un identificador explícito del revisor. La SQLite tampoco contiene una entidad de estudiante, currículo u objetivo canónico. Estas observaciones describen el snapshot de origen y no presuponen que todas esas piezas deban incorporarse ahora al destino.

## Seguimiento recomendado para futuras revisiones

1. Repetir las mismas comprobaciones en cada snapshot y registrar fecha, versión/huella de la fuente y cambios respecto a la línea base.
2. Desglosar transcripciones, profesores y análisis ausentes por estado y versión para acordar qué casos son esperados y cuáles requieren atención.
3. Documentar significado, rango y reglas de `qualityScore`, `pedagogicalScore` y `confidenceScore` antes de usarlos en informes o decisiones.
4. Añadir comprobaciones de dominio acordadas (por ejemplo, intervalos temporales, referencias JSON a unidades y consistencia entre estados) solo después de definir sus reglas esperadas.
5. Mantener este informe en agregado y sin transcripciones ni datos identificables; resolver cualquier incidencia sobre los datos privados en el entorno autorizado.
