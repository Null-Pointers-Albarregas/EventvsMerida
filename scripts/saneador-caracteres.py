"""
Limpia el JSON de eventos y normaliza texto y fechas.
Uso:
    python saneador-caracteres.py input.json output.json 
"""

import json
import re
import sys
import unicodedata
from datetime import datetime, timezone
from typing import Any, Dict

_WS_RE = re.compile(r"[ \t]+")

CATEGORY_CHOICES = {
    1: "Conciertos y Música",
    2: "Festivales y Ferias",
    3: "Cine y Teatro",
    4: "Exposiciones y Arte",
    5: "Gastronomía",
    6: "Conferencias, Talleres y Cursos",
    7: "Deportes y Actividad Física",
    8: "Fiestas y Vida Nocturna",
    9: "Familia e Infantil",
    10: "Tecnología y Ciencia",
    11: "Solidaridad y Causas Sociales",
    12: "Otros",
}

_KEYWORD_TO_ID = {
    "concierto": 1, "conciertos": 1, "musica": 1, "musical": 1, "jazz": 1, "orquesta": 1,
    "festival": 2, "feria": 2, "festivales": 2, "ferias": 2, "semana santa": 2, "comercio": 2, "convivencia": 2, "recreacion": 2, "emerita lvdica": 2,
    "cine": 3, "teatro": 3, "pelicula": 3, "peliculas": 3, "obra": 3, "danza": 3,
    "exposicion": 4, "exposiciones": 4, "arte": 4, "galeria": 4, "museo": 4,
    "gastronomia": 5, "gastronomica": 5, "comida": 5, "degustacion": 5,
    "conferencia": 6, "taller": 6, "talleres": 6, "curso": 6, "cursos": 6, "charla": 6, "congreso": 6, "educacion": 6, "literatura": 6,
    "deporte": 7, "deportes": 7, "actividad fisica": 7, "carrera": 7, "maraton": 7, "partido": 7,
    "fiesta": 8, "fiestas": 8, "noche": 8, "nocturna": 8, "verben": 8,
    "familia": 9, "infantil": 9, "ninos": 9, "nino": 9, "cuentacuentos": 9,
    "tecnologia": 10, "ciencia": 10, "robotica": 10,
    "solidaridad": 11, "solidario": 11, "benefico": 11,
    "otros": 12, "otro": 12, "varios": 12,
}

_CATEGORY_KEYS = {
    "category", "categoria", "category_name", "categoryname", "tipo", "tags",
    "categories", "categorias", "etiquetas", "categoria_nombre", "category-name",
}


def sanitize_text(s: str) -> str:
    """Limpia escapes comunes y espacios sobrantes en texto plano."""
    s = s.replace("\\n", " ")
    s = s.replace("\\,", ",")
    s = s.replace("\\\\", "\\")
    s = s.replace("\\", "")
    s = _WS_RE.sub(" ", s).strip()
    return s


def to_iso_utc_z(value: str) -> str:
    """Normaliza fechas ISO sin offset de zona horaria."""
    v = value.strip()

    # Fechas sin hora.
    if re.fullmatch(r"\d{4}-\d{2}-\d{2}", v):
        return f"{v}T00:00:00"

    v_norm = v.replace("Z", "+00:00") if v.endswith("Z") else v

    try:
        dt = datetime.fromisoformat(v_norm)
    except ValueError as e:
        raise ValueError(f"Formato de fecha/hora no soportado: {value!r}") from e

    # Eliminar tzinfo para no incluir offset
    dt_naive = dt.replace(tzinfo=None) if dt.tzinfo else dt

    # Devolver sin offset
    return dt_naive.strftime("%Y-%m-%dT%H:%M:%S")


def _strip_accents(s: str) -> str:
    return "".join(ch for ch in unicodedata.normalize("NFKD", s) if not unicodedata.combining(ch))


def normalize_category(value: str) -> Dict[str, Any]:
    """Normaliza una cadena de categoría y devuelve {'id': int, 'nombre': str}."""
    if not value or not value.strip():
        return {"id": 12, "nombre": CATEGORY_CHOICES[12]}

    s = sanitize_text(value).lower()
    s = _strip_accents(s)
    s = re.sub(r"[\/_\-]+", " ", s)
    s = re.sub(r"[^a-z0-9 ]+", " ", s)
    s = re.sub(r"\s+", " ", s).strip()

    for kw, cid in _KEYWORD_TO_ID.items():
        if kw in s:
            return {"id": cid, "nombre": CATEGORY_CHOICES[cid]}

    m = re.search(r"\b([1-9]|1[0-2])\b", s)
    if m:
        cid = int(m.group(1))
        return {"id": cid, "nombre": CATEGORY_CHOICES.get(cid, CATEGORY_CHOICES[12])}

    return {"id": 12, "nombre": CATEGORY_CHOICES[12]}


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

            k_lower = k.lower()
            if k_lower in _CATEGORY_KEYS:
                if isinstance(v, str):
                    new[k] = normalize_category(v)
                    continue

                if isinstance(v, list):
                    candidate = None
                    for item in v:
                        if isinstance(item, str) and item.strip():
                            candidate = item
                            break
                        if isinstance(item, dict):
                            for name_key in ("name", "nombre", "title", "category", "categoria"):
                                if name_key in item and isinstance(item[name_key], str) and item[name_key].strip():
                                    candidate = item[name_key]
                                    break
                            if candidate:
                                break
                    if candidate:
                        new[k] = normalize_category(candidate)
                    else:
                        new[k] = normalize_category(" ".join([str(x) for x in v]))
                    continue

                if isinstance(v, dict):
                    name = None
                    for name_key in ("name", "nombre", "title", "category", "categoria"):
                        if name_key in v and isinstance(v[name_key], str) and v[name_key].strip():
                            name = v[name_key]
                            break
                    if name:
                        new[k] = normalize_category(name)
                        continue
                    new[k] = walk_and_sanitize(v, skip_keys=skip_keys)
                    continue

                new[k] = walk_and_sanitize(v, skip_keys=skip_keys)
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