# Aprendizajes del proyecto

Registra aquí hallazgos que eviten errores o ciclos repetidos. Para cada entrada, anota el contexto, el problema o riesgo, la causa confirmada y la prevención comprobable. No incluyas datos personales, credenciales ni contenido identificable de alumnos. Si un hallazgo se convierte en regla permanente, actualiza también `AGENTS.md`.

## Hallazgos iniciales

### Los JSON de clips identifican el MP4 emparejado

En la exportación actual, cada JSON incluye `fileName` con el nombre exacto del MP4. Renombrar un vídeo sin actualizar su JSON rompe la correspondencia. Mantén juntos los pares y valida el campo al reorganizar o generar exports.

### El manifest de ejemplo y los JSON de clip tienen alcances distintos

La exportación revisada contiene un manifest a nivel de exportación con siete unidades pedagógicas y un JSON separado por clip. No hay que asumir que `lessonId` identifica una sesión ni que el manifest de muestra es un manifest por sesión. Los JSON de clip incluyen metadatos de tiempos y render, pero no una URL de YouTube; esa URL es una posibilidad futura propuesta por Tomás, no un campo disponible en la exportación actual.

### Las relaciones candidatas dependen de una versión del catálogo

El archivo de relaciones guarda la versión y el SHA-256 del catálogo usado para construirlo. Tras editar el contenido del catálogo, recalcula la huella y revisa las relaciones; el archivo sigue siendo candidato hasta que una persona lo apruebe.

### La base SQLite existente no es el modelo objetivo

`dev.db` representa tablas operativas del pipeline de App Clips, como `Lesson`, transcripciones, unidades pedagógicas y clips. Úsala como fuente para entender la ingesta actual, no como sustituto del modelo compartido que se está diseñando; no des por hecho que `Lesson` equivale a una sesión grabada.

La ausencia de una entidad en la SQLite no significa que falte en el modelo objetivo: el brief exige entidades estables Alumno y Profesor, aunque la fuente actual solo tenga `Teacher`. Contrasta siempre el esquema existente con los requisitos explícitos del brief.

### Distinción conceptual entre lección y sesión

Tomás ha aclarado que una lección es contenido pedagógico y una sesión es una clase concreta, que puede cubrir parte de una lección o varias. Mantén separados esos conceptos. Sigue pendiente mapear la tabla fuente `Lesson` a ese modelo y cerrar las cardinalidades que dependan del flujo real.
