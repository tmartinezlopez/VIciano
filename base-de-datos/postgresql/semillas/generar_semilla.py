#!/usr/bin/env python3
"""Genera una semilla PostgreSQL con el catálogo versionado y fixtures ficticios."""
from __future__ import annotations

import argparse
import json
from hashlib import sha256
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[3]
CATALOG_PATH = ROOT / "referencias/curriculo/matematicas/2eso/catalogo-learning-targets/catalogo-v0.1.json"
RELATIONS_PATH = ROOT / "referencias/curriculo/matematicas/2eso/catalogo-learning-targets/candidatas/relaciones-v0.1-candidata.json"
DEFAULT_OUTPUT = ROOT / "base-de-datos/postgresql/semillas/datos-iniciales-v0.1.sql"


def text_sql(value: Any) -> str:
    if value is None:
        return "NULL::text"
    return "'" + str(value).replace("'", "''") + "'"


def json_sql(value: Any) -> str:
    encoded = json.dumps(value, ensure_ascii=False, separators=(",", ":"))
    return text_sql(encoded) + "::jsonb"


def bool_sql(value: Any) -> str:
    return "TRUE" if value is True else "FALSE"


def values(rows: list[list[str]]) -> str:
    return ",\n".join("  (" + ", ".join(row) + ")" for row in rows)


def build_seed() -> str:
    catalog = json.loads(CATALOG_PATH.read_text(encoding="utf-8"))
    rel_set = json.loads(RELATIONS_PATH.read_text(encoding="utf-8"))
    source_hash = sha256(CATALOG_PATH.read_bytes()).hexdigest()
    built_against = rel_set.get("built_against_catalog", {})
    if built_against.get("catalog_id") != catalog["catalog_id"]:
        raise SystemExit("El conjunto de relaciones apunta a otro catálogo.")
    if built_against.get("catalog_version") != catalog["catalog_version"]:
        raise SystemExit("El conjunto de relaciones apunta a otra versión de catálogo.")
    if built_against.get("catalog_sha256") != source_hash:
        raise SystemExit("El hash del catálogo no coincide con el registrado por las relaciones candidatas.")
    catalog_meta = {k: v for k, v in catalog.items() if k != "domains"}
    relation_meta = {k: v for k, v in rel_set.items() if k != "relationships"}
    catalog_code = text_sql(catalog["catalog_id"])
    catalog_version = text_sql(catalog["catalog_version"])

    chunks = ["""-- Generado por generar_semilla.py a partir del catálogo disponible en referencias/.
-- Contiene una sesión y un clip ficticios; no incluye registros privados.
BEGIN;
SET search_path TO pedagogia, public;

INSERT INTO curso (codigo, nombre) VALUES ('2ESO', '2.º ESO')
ON CONFLICT (codigo) DO UPDATE SET nombre = EXCLUDED.nombre;
INSERT INTO asignatura (codigo, nombre) VALUES ('MAT', 'Matemáticas')
ON CONFLICT (codigo) DO UPDATE SET nombre = EXCLUDED.nombre;
INSERT INTO curso_asignatura (curso_id, asignatura_id)
SELECT c.id, a.id FROM curso c CROSS JOIN asignatura a
WHERE c.codigo = '2ESO' AND a.codigo = 'MAT'
ON CONFLICT (curso_id, asignatura_id) DO NOTHING;

INSERT INTO alumno (sistema_origen, id_externo) VALUES ('fixture', 'alumno-demo-001')
ON CONFLICT (sistema_origen, id_externo) DO NOTHING;
INSERT INTO profesor (sistema_origen, id_externo) VALUES ('fixture', 'profesor-demo-001')
ON CONFLICT (sistema_origen, id_externo) DO NOTHING;

INSERT INTO sesion (sistema_origen, id_externo, alumno_id, profesor_id, curso_asignatura_id, manifest_actual)
SELECT 'fixture', 'sesion-demo-001', al.id, pr.id, ca.id,
  '{"fixture":true,"schemaVersion":"demo-1","originRecordId":"registro-demo-001","pedagogicalUnits":[{"id":"unidad-demo-001","sequence":1,"startSeconds":0,"endSeconds":60,"title":"Ejemplo ficticio de unidad","topic":"Contenido de muestra","objective":"Comprobar la importación del modelo"}]}'::jsonb
FROM alumno al CROSS JOIN profesor pr CROSS JOIN curso_asignatura ca
WHERE al.sistema_origen = 'fixture' AND al.id_externo = 'alumno-demo-001'
  AND pr.sistema_origen = 'fixture' AND pr.id_externo = 'profesor-demo-001'
  AND ca.curso_id = (SELECT id FROM curso WHERE codigo = '2ESO')
  AND ca.asignatura_id = (SELECT id FROM asignatura WHERE codigo = 'MAT')
ON CONFLICT (sistema_origen, id_externo) DO UPDATE SET
  alumno_id = EXCLUDED.alumno_id, profesor_id = EXCLUDED.profesor_id,
  curso_asignatura_id = EXCLUDED.curso_asignatura_id, manifest_actual = EXCLUDED.manifest_actual;

INSERT INTO clip (sesion_id, sistema_origen, id_externo, secuencia, inicio_segundos, fin_segundos, titulo, tema_principal, objetivo_aprendizaje, nombre_archivo_origen)
SELECT s.id, 'fixture', 'clip-demo-001', 1, 0, 60,
  'Clip de muestra', 'Contenido de muestra', 'Probar consulta del catálogo', 'clip-demo-001.mp4'
FROM sesion s WHERE s.sistema_origen = 'fixture' AND s.id_externo = 'sesion-demo-001'
ON CONFLICT (sistema_origen, id_externo) DO UPDATE SET
  sesion_id = EXCLUDED.sesion_id, secuencia = EXCLUDED.secuencia,
  inicio_segundos = EXCLUDED.inicio_segundos, fin_segundos = EXCLUDED.fin_segundos,
  titulo = EXCLUDED.titulo, tema_principal = EXCLUDED.tema_principal,
  objetivo_aprendizaje = EXCLUDED.objetivo_aprendizaje, nombre_archivo_origen = EXCLUDED.nombre_archivo_origen;
"""]

    course_subject = "(SELECT ca.id FROM curso_asignatura ca JOIN curso c ON c.id = ca.curso_id JOIN asignatura a ON a.id = ca.asignatura_id WHERE c.codigo = '2ESO' AND a.codigo = 'MAT')"
    chunks.append(
        "\nINSERT INTO version_catalogo_objetivos (curso_asignatura_id, codigo, version, estado, fecha_snapshot, alcance, proposito, completitud_declarada, metadatos_fuente)\n"
        + "VALUES (" + course_subject + ", " + catalog_code + ", " + catalog_version + ", "
        + text_sql(catalog.get("status")) + ", " + text_sql(catalog.get("frozen_snapshot_date")) + "::date, "
        + text_sql(catalog.get("scope")) + ", " + text_sql(catalog.get("purpose")) + ", "
        + bool_sql(catalog.get("completeness_claim")) + ", " + json_sql(catalog_meta) + ")\n"
        + "ON CONFLICT (codigo, version) DO UPDATE SET estado = EXCLUDED.estado, fecha_snapshot = EXCLUDED.fecha_snapshot,\n"
        + "  alcance = EXCLUDED.alcance, proposito = EXCLUDED.proposito, completitud_declarada = EXCLUDED.completitud_declarada,\n"
        + "  metadatos_fuente = EXCLUDED.metadatos_fuente, curso_asignatura_id = EXCLUDED.curso_asignatura_id;\n"
    )

    domain_rows = [
        [text_sql(d["domain_id"]), text_sql(d["title"]), json_sql(d.get("source_basis", [])), json_sql(d.get("notes", []))]
        for d in catalog["domains"]
    ]
    chunks.append(
        "\nINSERT INTO dominio_objetivo (version_catalogo_id, codigo_externo, titulo, base_fuente, notas)\n"
        + "SELECT vc.id, src.codigo, src.titulo, src.base_fuente, src.notas\nFROM version_catalogo_objetivos vc CROSS JOIN (VALUES\n"
        + values(domain_rows)
        + "\n) AS src(codigo, titulo, base_fuente, notas)\nWHERE vc.codigo = " + catalog_code + " AND vc.version = " + catalog_version + "\n"
        + "ON CONFLICT (version_catalogo_id, codigo_externo) DO UPDATE SET titulo = EXCLUDED.titulo, base_fuente = EXCLUDED.base_fuente, notas = EXCLUDED.notas;\n"
    )

    targets = [(domain, target) for domain in catalog["domains"] for target in domain["targets"]]
    chunks.append(
        "\nINSERT INTO objetivo_aprendizaje (codigo_estable) VALUES\n"
        + values([[text_sql(t["learning_target_id"])] for _, t in targets])
        + "\nON CONFLICT (codigo_estable) DO NOTHING;\n"
    )
    entry_rows = [
        [text_sql(d["domain_id"]), text_sql(t["learning_target_id"]), text_sql(t["canonical_label"]), text_sql(t["type"]), text_sql(t["status"])]
        for d, t in targets
    ]
    chunks.append(
        "\nINSERT INTO entrada_catalogo_objetivo (version_catalogo_id, dominio_objetivo_id, objetivo_aprendizaje_id, id_objetivo_externo, etiqueta, tipo, estado)\n"
        + "SELECT vc.id, d.id, oa.id, src.id_externo, src.etiqueta, src.tipo, src.estado\nFROM (VALUES\n"
        + values(entry_rows)
        + "\n) AS src(codigo_dominio, id_externo, etiqueta, tipo, estado)\n"
        + "JOIN version_catalogo_objetivos vc ON vc.codigo = " + catalog_code + " AND vc.version = " + catalog_version + "\n"
        + "JOIN dominio_objetivo d ON d.version_catalogo_id = vc.id AND d.codigo_externo = src.codigo_dominio\n"
        + "JOIN objetivo_aprendizaje oa ON oa.codigo_estable = src.id_externo\n"
        + "ON CONFLICT (version_catalogo_id, id_objetivo_externo) DO UPDATE SET dominio_objetivo_id = EXCLUDED.dominio_objetivo_id,\n"
        + "  objetivo_aprendizaje_id = EXCLUDED.objetivo_aprendizaje_id, etiqueta = EXCLUDED.etiqueta, tipo = EXCLUDED.tipo, estado = EXCLUDED.estado;\n"
    )

    chunks.append(
        "\nINSERT INTO conjunto_relaciones_objetivos (version_catalogo_id, codigo, version, estado, es_canonico, metadatos_fuente)\n"
        + "SELECT vc.id, " + text_sql(rel_set["relationship_set_id"]) + ", " + text_sql(rel_set["relationship_set_version"]) + ", "
        + text_sql(rel_set["status"]) + ", " + bool_sql(rel_set.get("canonical")) + ", " + json_sql(relation_meta) + "\n"
        + "FROM version_catalogo_objetivos vc WHERE vc.codigo = " + catalog_code + " AND vc.version = " + catalog_version + "\n"
        + "ON CONFLICT (codigo, version) DO UPDATE SET estado = EXCLUDED.estado, es_canonico = EXCLUDED.es_canonico,\n"
        + "  metadatos_fuente = EXCLUDED.metadatos_fuente, version_catalogo_id = EXCLUDED.version_catalogo_id;\n"
    )
    relation_rows = [
        [
            text_sql(r["relationship_id"]), text_sql(r["source_target"]), text_sql(r["relationship_type"]),
            text_sql(r["target_target"]), text_sql(r["status"]), bool_sql(r.get("canonical")),
            text_sql(r.get("warrant")), text_sql(r.get("review_priority")), text_sql(r.get("source_anchor")),
            text_sql(r.get("rationale")), json_sql(r.get("notes", [])),
        ]
        for r in rel_set["relationships"]
    ]
    chunks.append(
        "\nINSERT INTO relacion_objetivos (conjunto_relaciones_id, version_catalogo_id, id_relacion_externa, entrada_origen_id, tipo_relacion, entrada_destino_id, estado, es_canonica, requisito_revision, prioridad_revision, ancla_fuente, justificacion, notas)\n"
        + "SELECT cr.id, vc.id, src.id_relacion, origen.id, src.tipo, destino.id, src.estado, src.es_canonica, src.revision, src.prioridad, src.ancla, src.justificacion, src.notas\n"
        + "FROM (VALUES\n" + values(relation_rows) + "\n) AS src(id_relacion, id_origen, tipo, id_destino, estado, es_canonica, revision, prioridad, ancla, justificacion, notas)\n"
        + "JOIN version_catalogo_objetivos vc ON vc.codigo = " + catalog_code + " AND vc.version = " + catalog_version + "\n"
        + "JOIN conjunto_relaciones_objetivos cr ON cr.version_catalogo_id = vc.id AND cr.codigo = "
        + text_sql(rel_set["relationship_set_id"]) + " AND cr.version = " + text_sql(rel_set["relationship_set_version"]) + "\n"
        + "JOIN entrada_catalogo_objetivo origen ON origen.version_catalogo_id = vc.id AND origen.id_objetivo_externo = src.id_origen\n"
        + "JOIN entrada_catalogo_objetivo destino ON destino.version_catalogo_id = vc.id AND destino.id_objetivo_externo = src.id_destino\n"
        + "ON CONFLICT (conjunto_relaciones_id, id_relacion_externa) DO UPDATE SET entrada_origen_id = EXCLUDED.entrada_origen_id,\n"
        + "  tipo_relacion = EXCLUDED.tipo_relacion, entrada_destino_id = EXCLUDED.entrada_destino_id, estado = EXCLUDED.estado,\n"
        + "  es_canonica = EXCLUDED.es_canonica, requisito_revision = EXCLUDED.requisito_revision, prioridad_revision = EXCLUDED.prioridad_revision,\n"
        + "  ancla_fuente = EXCLUDED.ancla_fuente, justificacion = EXCLUDED.justificacion, notas = EXCLUDED.notas;\n"
    )
    chunks.append("\nCOMMIT;\n")
    return "".join(chunks)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(build_seed(), encoding="utf-8")
    print(f"Generado: {args.output}")


if __name__ == "__main__":
    main()
