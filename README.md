# Virtut × App Clips Classes

Este repositorio prepara una base de datos pedagógica clara, extensible y reutilizable para App Clips Classes y futuros usos, incluidos proyectos de IA. El brief sitúa App Clips como origen inicial y Virtut como consumidor futuro conocido, no como único criterio del diseño. El hito inmediato es el modelo entidad-relación y una primera versión PostgreSQL importable por Luis; con Nacho se concretarán el contrato de ingesta y el formato operativo de la checklist docente.

## Mapa

- `AGENTS.md`: reglas de trabajo, datos, herramientas y skills.
- `APRENDIZAJES.md`: hallazgos reutilizables para evitar repetir errores.
- `documentacion/`: brief, arquitectura, contratos, decisiones, análisis e informes de entrega.
- `referencias/`: currículo y catálogo de learning targets por curso.
- `base-de-datos/postgresql/`: esquema, migraciones, semillas y entregas.
- `ejemplos/`: solo fixtures sintéticos o sanitizados.
- `documentacion/entregas/primera-entrega-v0.1/`: informe y acceso al paquete técnico de la primera entrega.
- `datos-privados/`: fuentes locales sensibles; está excluida de Git.

## Estado inicial

Git está inicializado en `main`, sin commit ni remoto configurado. Todavía no hay código de aplicación ni comandos de build. Ya existe un borrador PostgreSQL v0.1 con catálogo y fixtures sintéticos; se importó y comprobó en PostgreSQL 16 temporal antes de preparar el paquete para Luis.

El brief y el libro fuente se conservan localmente, pero están excluidos de Git mientras no se confirme la visibilidad del repositorio y el permiso de redistribución. La base SQLite, las sesiones, los vídeos y las respuestas históricas de análisis permanecen en `datos-privados/`.
