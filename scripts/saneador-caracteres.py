#!/usr/bin/env python3
"""Limpia el JSON de eventos y normaliza texto y fechas.
    python saneador-caracteres.py input.json output.json """

import json
import re
import sys
from datetime import datetime, timezone
from typing import Any, Dict


_WS_RE = re.compile(r"[ \t]+")


def sanitize_text(s: str) -> str:
    """Limpia escapes comunes y espacios sobrantes en texto plano."""
    s = s.replace("\\n", " ")
    s = s.replace("\\,", ",")
    s = s.replace("\\\\", "\\")
    s = s.replace("\\", "")
    s = _WS_RE.sub(" ", s).strip()
    return s


def to_iso_utc_z(value: str) -> str:
    """Normaliza fechas ISO manteniendo el offset original."""
    v = value.strip()

    # Fechas sin hora.
    if re.fullmatch(r"\d{4}-\d{2}-\d{2}", v):
        return f"{v}T00:00:00.000"

    v_norm = v.replace("Z", "+00:00") if v.endswith("Z") else v

    try:
        dt = datetime.fromisoformat(v_norm)
    except ValueError as e:
        raise ValueError(f"Formato de fecha/hora no soportado: {value!r}") from e

    # Si no trae zona, asumimos UTC.
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)

    out = dt.isoformat(timespec="milliseconds")
    return out


def walk_and_sanitize(obj: Any, *, skip_keys: set[str] | None = None) -> Any:
    """Recorre dict/list y limpia strings, salvo claves excluidas."""
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
    """Lee un JSON, lo sanea y escribe el resultado en otro archivo."""
    if len(sys.argv) != 3:
        print("Uso: python saneador-caracteres.py <input.json> <output.json>", file=sys.stderr)
        return 2

    in_path, out_path = sys.argv[1], sys.argv[2]

    with open(in_path, "r", encoding="utf-8") as f:
        data = json.load(f)

    sanitized = walk_and_sanitize(data, skip_keys={"fetched_at"})

    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(sanitized, f, ensure_ascii=False, indent=2)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())