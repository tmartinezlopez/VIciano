-- Modelo relacional inicial para la base pedagógica compartida.
-- La checklist, sus preguntas y el historial de validación quedan para una fase posterior.
BEGIN;

CREATE SCHEMA IF NOT EXISTS pedagogia;
SET search_path TO pedagogia, public;

CREATE TABLE alumno (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sistema_origen TEXT NOT NULL,
    id_externo TEXT NOT NULL,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_alumno_origen UNIQUE (sistema_origen, id_externo)
);
COMMENT ON TABLE alumno IS 'Identidad estable del alumno; no almacena nombre ni otros datos personales en este borrador.';

CREATE TABLE profesor (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sistema_origen TEXT NOT NULL,
    id_externo TEXT NOT NULL,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_profesor_origen UNIQUE (sistema_origen, id_externo)
);
COMMENT ON TABLE profesor IS 'Identidad estable del profesor según el sistema de origen.';

CREATE TABLE curso (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo TEXT NOT NULL UNIQUE,
    nombre TEXT NOT NULL
);

CREATE TABLE asignatura (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo TEXT NOT NULL UNIQUE,
    nombre TEXT NOT NULL
);

CREATE TABLE curso_asignatura (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    curso_id BIGINT NOT NULL REFERENCES curso(id),
    asignatura_id BIGINT NOT NULL REFERENCES asignatura(id),
    CONSTRAINT uq_curso_asignatura UNIQUE (curso_id, asignatura_id)
);
COMMENT ON TABLE curso_asignatura IS 'Combinación válida de curso y asignatura para contextualizar una sesión o fuente.';

CREATE TABLE sesion (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sistema_origen TEXT NOT NULL,
    id_externo TEXT NOT NULL,
    alumno_id BIGINT NOT NULL REFERENCES alumno(id),
    profesor_id BIGINT NOT NULL REFERENCES profesor(id),
    curso_asignatura_id BIGINT NOT NULL REFERENCES curso_asignatura(id),
    manifest_actual JSONB NOT NULL,
    creada_en TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_sesion_origen UNIQUE (sistema_origen, id_externo),
    CONSTRAINT ck_sesion_manifest_objeto CHECK (jsonb_typeof(manifest_actual) = 'object')
);
COMMENT ON TABLE sesion IS 'Clase concreta. El manifest vigente se reemplaza y reindexa bajo la misma identidad; en v0.1 se supone un alumno y un profesor por sesión.';
COMMENT ON COLUMN sesion.id_externo IS 'Referencia estable del sistema de origen; no implica que la entidad de origen Lesson sea una sesión.';
COMMENT ON COLUMN sesion.manifest_actual IS 'Copia completa del manifest vigente de la sesión. No conserva snapshots anteriores en v0.1.';

CREATE TABLE clip (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sesion_id BIGINT NOT NULL REFERENCES sesion(id) ON DELETE CASCADE,
    sistema_origen TEXT NOT NULL,
    id_externo TEXT NOT NULL,
    secuencia INTEGER,
    inicio_segundos NUMERIC(12, 3) NOT NULL,
    fin_segundos NUMERIC(12, 3) NOT NULL,
    titulo TEXT,
    tema_principal TEXT,
    objetivo_aprendizaje TEXT,
    nombre_archivo_origen TEXT,
    metadatos_adicionales JSONB NOT NULL DEFAULT '{}'::jsonb,
    CONSTRAINT uq_clip_origen UNIQUE (sistema_origen, id_externo),
    CONSTRAINT ck_clip_intervalo CHECK (inicio_segundos >= 0 AND fin_segundos > inicio_segundos),
    CONSTRAINT ck_clip_metadatos_objeto CHECK (jsonb_typeof(metadatos_adicionales) = 'object')
);
COMMENT ON TABLE clip IS 'Metadatos de consulta del segmento. Los detalles técnicos de render siguen en App Clips; no se incluye URL de YouTube.';

CREATE TABLE version_curricular (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    curso_asignatura_id BIGINT NOT NULL REFERENCES curso_asignatura(id),
    nombre_fuente TEXT NOT NULL,
    version_fuente TEXT NOT NULL,
    estado TEXT,
    metadatos_fuente JSONB NOT NULL DEFAULT '{}'::jsonb,
    CONSTRAINT uq_version_curricular UNIQUE (curso_asignatura_id, nombre_fuente, version_fuente),
    CONSTRAINT ck_version_curricular_metadatos CHECK (jsonb_typeof(metadatos_fuente) = 'object')
);

CREATE TABLE unidad_curricular (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    version_curricular_id BIGINT NOT NULL REFERENCES version_curricular(id) ON DELETE CASCADE,
    id_externo TEXT NOT NULL,
    unidad_padre_id BIGINT,
    tipo TEXT,
    titulo TEXT NOT NULL,
    descripcion TEXT,
    metadatos_fuente JSONB NOT NULL DEFAULT '{}'::jsonb,
    CONSTRAINT uq_unidad_origen UNIQUE (version_curricular_id, id_externo),
    CONSTRAINT uq_unidad_version_id UNIQUE (version_curricular_id, id),
    CONSTRAINT fk_unidad_padre_misma_version
        FOREIGN KEY (version_curricular_id, unidad_padre_id)
        REFERENCES unidad_curricular (version_curricular_id, id),
    CONSTRAINT ck_unidad_no_es_su_padre CHECK (unidad_padre_id IS NULL OR unidad_padre_id <> id),
    CONSTRAINT ck_unidad_metadatos_objeto CHECK (jsonb_typeof(metadatos_fuente) = 'object')
);
COMMENT ON TABLE unidad_curricular IS 'Contenido curricular como lección, tema o unidad; no se confunde con la sesión grabada.';

CREATE TABLE sesion_unidad_curricular (
    sesion_id BIGINT NOT NULL REFERENCES sesion(id) ON DELETE CASCADE,
    unidad_curricular_id BIGINT NOT NULL REFERENCES unidad_curricular(id),
    PRIMARY KEY (sesion_id, unidad_curricular_id)
);
COMMENT ON TABLE sesion_unidad_curricular IS 'Asociación entre una sesión y el contenido curricular abordado. No registra intervalos temporales.';

CREATE TABLE version_catalogo_objetivos (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    curso_asignatura_id BIGINT REFERENCES curso_asignatura(id),
    codigo TEXT NOT NULL,
    version TEXT NOT NULL,
    estado TEXT NOT NULL,
    fecha_snapshot DATE,
    alcance TEXT,
    proposito TEXT,
    completitud_declarada BOOLEAN,
    metadatos_fuente JSONB NOT NULL DEFAULT '{}'::jsonb,
    CONSTRAINT uq_catalogo_codigo_version UNIQUE (codigo, version),
    CONSTRAINT ck_catalogo_metadatos_objeto CHECK (jsonb_typeof(metadatos_fuente) = 'object')
);
COMMENT ON TABLE version_catalogo_objetivos IS 'Versión del catálogo y procedencia conservada. El estado de origen no se interpreta como validación pedagógica definitiva.';

CREATE TABLE dominio_objetivo (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    version_catalogo_id BIGINT NOT NULL REFERENCES version_catalogo_objetivos(id) ON DELETE CASCADE,
    codigo_externo TEXT NOT NULL,
    titulo TEXT NOT NULL,
    base_fuente JSONB NOT NULL DEFAULT '[]'::jsonb,
    notas JSONB NOT NULL DEFAULT '[]'::jsonb,
    CONSTRAINT uq_dominio_catalogo_codigo UNIQUE (version_catalogo_id, codigo_externo),
    CONSTRAINT uq_dominio_catalogo_id UNIQUE (version_catalogo_id, id),
    CONSTRAINT ck_dominio_base_array CHECK (jsonb_typeof(base_fuente) = 'array'),
    CONSTRAINT ck_dominio_notas_array CHECK (jsonb_typeof(notas) = 'array')
);

CREATE TABLE objetivo_aprendizaje (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo_estable TEXT NOT NULL UNIQUE
);
COMMENT ON TABLE objetivo_aprendizaje IS 'Identidad interna reutilizable. El código inicial se toma del catálogo disponible; su gobierno entre versiones queda pendiente.';

CREATE TABLE entrada_catalogo_objetivo (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    version_catalogo_id BIGINT NOT NULL REFERENCES version_catalogo_objetivos(id) ON DELETE CASCADE,
    dominio_objetivo_id BIGINT NOT NULL,
    objetivo_aprendizaje_id BIGINT NOT NULL REFERENCES objetivo_aprendizaje(id),
    id_objetivo_externo TEXT NOT NULL,
    etiqueta TEXT NOT NULL,
    tipo TEXT NOT NULL,
    estado TEXT NOT NULL,
    CONSTRAINT uq_entrada_catalogo_origen UNIQUE (version_catalogo_id, id_objetivo_externo),
    CONSTRAINT uq_entrada_catalogo_id UNIQUE (version_catalogo_id, id),
    CONSTRAINT fk_entrada_dominio_misma_version
        FOREIGN KEY (version_catalogo_id, dominio_objetivo_id)
        REFERENCES dominio_objetivo (version_catalogo_id, id)
);
COMMENT ON TABLE entrada_catalogo_objetivo IS 'Descripción de un objetivo dentro de una versión concreta; conserva la etiqueta e ID de origen de esa versión.';

CREATE TABLE conjunto_relaciones_objetivos (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    version_catalogo_id BIGINT NOT NULL REFERENCES version_catalogo_objetivos(id),
    codigo TEXT NOT NULL,
    version TEXT NOT NULL,
    estado TEXT NOT NULL,
    es_canonico BOOLEAN NOT NULL DEFAULT FALSE,
    metadatos_fuente JSONB NOT NULL DEFAULT '{}'::jsonb,
    CONSTRAINT uq_conjunto_relaciones UNIQUE (codigo, version),
    CONSTRAINT uq_conjunto_id_version UNIQUE (id, version_catalogo_id),
    CONSTRAINT ck_conjunto_metadatos_objeto CHECK (jsonb_typeof(metadatos_fuente) = 'object')
);

CREATE TABLE relacion_objetivos (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    conjunto_relaciones_id BIGINT NOT NULL,
    version_catalogo_id BIGINT NOT NULL,
    id_relacion_externa TEXT NOT NULL,
    entrada_origen_id BIGINT NOT NULL,
    tipo_relacion TEXT NOT NULL,
    entrada_destino_id BIGINT NOT NULL,
    estado TEXT NOT NULL,
    es_canonica BOOLEAN NOT NULL DEFAULT FALSE,
    requisito_revision TEXT,
    prioridad_revision TEXT,
    ancla_fuente TEXT,
    justificacion TEXT,
    notas JSONB NOT NULL DEFAULT '[]'::jsonb,
    CONSTRAINT uq_relacion_conjunto_origen UNIQUE (conjunto_relaciones_id, id_relacion_externa),
    CONSTRAINT fk_relacion_conjunto_misma_version
        FOREIGN KEY (conjunto_relaciones_id, version_catalogo_id)
        REFERENCES conjunto_relaciones_objetivos (id, version_catalogo_id),
    CONSTRAINT fk_relacion_origen_misma_version
        FOREIGN KEY (version_catalogo_id, entrada_origen_id)
        REFERENCES entrada_catalogo_objetivo (version_catalogo_id, id),
    CONSTRAINT fk_relacion_destino_misma_version
        FOREIGN KEY (version_catalogo_id, entrada_destino_id)
        REFERENCES entrada_catalogo_objetivo (version_catalogo_id, id),
    CONSTRAINT ck_relacion_notas_array CHECK (jsonb_typeof(notas) = 'array')
);
COMMENT ON TABLE relacion_objetivos IS 'Relaciones entre entradas de una misma versión. Se conserva el estado propuesto/no canónico del origen.';

CREATE INDEX ix_sesion_alumno ON sesion (alumno_id);
CREATE INDEX ix_sesion_profesor ON sesion (profesor_id);
CREATE INDEX ix_sesion_contexto ON sesion (curso_asignatura_id);
CREATE INDEX ix_clip_sesion ON clip (sesion_id);
CREATE INDEX ix_unidad_version_padre ON unidad_curricular (version_curricular_id, unidad_padre_id);
CREATE INDEX ix_sesion_unidad_unidad ON sesion_unidad_curricular (unidad_curricular_id);
CREATE INDEX ix_version_curricular_contexto ON version_curricular (curso_asignatura_id);
CREATE INDEX ix_catalogo_contexto ON version_catalogo_objetivos (curso_asignatura_id);
CREATE INDEX ix_dominio_version ON dominio_objetivo (version_catalogo_id);
CREATE INDEX ix_entrada_objetivo ON entrada_catalogo_objetivo (objetivo_aprendizaje_id);
CREATE INDEX ix_entrada_dominio ON entrada_catalogo_objetivo (dominio_objetivo_id);
CREATE INDEX ix_relacion_origen ON relacion_objetivos (entrada_origen_id);
CREATE INDEX ix_relacion_destino ON relacion_objetivos (entrada_destino_id);
CREATE INDEX ix_relacion_estado ON relacion_objetivos (estado, es_canonica);

COMMIT;
