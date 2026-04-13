#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Sanitiza el JSON de eventos:
- NO modifica fetched_at
- Limpia textos (\\n, \\, \\,) en campos string (incluido raw.*)
- Normaliza dtstart y dtend a ISO-8601 UTC con sufijo Z:
    * Si no hay hora -> T00:00:00.000Z
    * Si hay offset (ej: +01:00) -> convierte a UTC
Uso:
  python saneador-caracteres.py input.json output.json
"""

from __future__ import annotations

import json
import re
import sys
from datetime import datetime, timezone
from typing import Any, Dict


_WS_RE = re.compile(r"[ \t]+")


def sanitize_text(s: str) -> str:
    # Primero normalizamos escapes típicos del iCal/JSON de origen
    s = s.replace("\\n", " ")   # literal backslash+n -> espacio
    s = s.replace("\\,", ",")   # literal backslash+comma -> comma
    s = s.replace("\\\\", "\\") # doble backslash -> backslash simple

    # Si aún quedan backslashes sueltos (muy típicos en este feed), los quitamos
    # Nota: no afecta a URLs normales (no suelen llevar '\').
    s = s.replace("\\", "")

    # Compacta espacios
    s = _WS_RE.sub(" ", s).strip()
    return s


def to_iso_utc_z(value: str) -> str:
    """
    Normaliza fechas ISO-8601 preservando zona horaria original:
      - YYYY-MM-DD -> YYYY-MM-DDT00:00:00.000Z
      - YYYY-MM-DDTHH:MM:SS+01:00 -> mantiene +01:00
      - YYYY-MM-DDTHH:MM:SSZ -> normaliza a .mmmZ
    """
    v = value.strip()

    # Solo fecha
    if re.fullmatch(r"\d{4}-\d{2}-\d{2}", v):
        return f"{v}T00:00:00.000"

    # Intentos con fromisoformat (acepta +01:00, y también sin Z si tiene offset)
    # Normalizamos Z -> +00:00 para parsear.
    v_norm = v.replace("Z", "+00:00") if v.endswith("Z") else v

    try:
        dt = datetime.fromisoformat(v_norm)
    except ValueError as e:
        raise ValueError(f"Formato de fecha/hora no soportado: {value!r}") from e

    # Si viene naive (sin tzinfo), asumimos UTC
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)

    # Mantener zona horaria original, sin convertir a UTC
    # ISO con milisegundos exactos
    out = dt.isoformat(timespec="milliseconds")
    return out


def walk_and_sanitize(obj: Any, *, skip_keys: set[str] | None = None) -> Any:
    """
    Recorre recursivamente dict/list y sanitiza:
      - str -> sanitize_text
      - pero respeta keys que queramos excluir (ej: fetched_at)
    """
    if skip_keys is None:
        skip_keys = set()

    if isinstance(obj, dict):
        new: Dict[str, Any] = {}
        for k, v in obj.items():
            if k in skip_keys:
                new[k] = v
                continue

            if k in ("dtstart", "dtend") and isinstance(v, str):
                new[k] = to_iso_utc_z(v)
                continue

            new[k] = walk_and_sanitize(v, skip_keys=skip_keys)
        return new

    if isinstance(obj, list):
        return [walk_and_sanitize(x, skip_keys=skip_keys) for x in obj]

    if isinstance(obj, str):
        return sanitize_text(obj)

    return obj


def main() -> int:
    if len(sys.argv) != 3:
        print("Uso: python sanitize_eventos_marzo.py <input.json> <output.json>", file=sys.stderr)
        return 2

    in_path, out_path = sys.argv[1], sys.argv[2]

    with open(in_path, "r", encoding="utf-8") as f:
        data = json.load(f)

    # NO tocar fetched_at
    sanitized = walk_and_sanitize(data, skip_keys={"fetched_at"})

    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(sanitized, f, ensure_ascii=False, indent=2)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())