#!/usr/bin/env python3
"""
Descarga e interpreta eventos de The Events Calendar desde:
  /wp-json/wp/v2/tribe_events?per_page=50&page=1&status=publish

- Paginación automática usando headers X-WP-TotalPages
- Rate limit (pausa entre requests)
- Normaliza a un JSON propio
- Si el endpoint expone meta, intenta leer _EventStartDate/_EventEndDate

Uso:
  python fetch_tribe_events.py --base-url https://example.com --out events.json
"""

from __future__ import annotations

import argparse
import json
import re
import time
from typing import Any, Dict, List, Optional, Tuple

import requests


HTML_TAG_RE = re.compile(r"<[^>]+>")


def strip_html(s: Optional[str]) -> Optional[str]:
    if s is None:
        return None
    return HTML_TAG_RE.sub("", s).strip()


import json

def fetch_page(session, url, params, timeout=30):
    r = session.get(url, params=params, timeout=timeout)
    r.raise_for_status()

    total_pages = int(r.headers.get("X-WP-TotalPages", "1"))

    # Manejo BOM UTF-8: decodifica con utf-8-sig (quita BOM si existe)
    raw = r.content.decode("utf-8-sig", errors="strict")
    items = json.loads(raw)

    if not isinstance(items, list):
        # Para depurar cuando WP devuelve un objeto con error
        raise ValueError(f"Se esperaba una lista JSON, pero llegó {type(items)}: {items}")

    return items, total_pages


def normalize_event(e: Dict[str, Any]) -> Dict[str, Any]:
    """
    Mapea el objeto WP REST del evento a un JSON más simple.
    Nota: la fecha real del evento suele estar en meta (_EventStartDate/_EventEndDate)
    si el servidor expone esos metadatos por REST.
    """
    meta = e.get("meta") or {}

    return {
        "id": e.get("id"),
        "slug": e.get("slug"),
        "url": e.get("link"),
        "status": e.get("status"),
        # Título/descr vienen como HTML en rendered
        "title": strip_html((e.get("title") or {}).get("rendered")),
        "excerpt": strip_html((e.get("excerpt") or {}).get("rendered")),
        # OJO: date es fecha de publicación del post, no necesariamente del evento
        "published_at": e.get("date"),
        "modified_at": e.get("modified"),
        # Fechas del evento (si están expuestas)
        "event_start": meta.get("_EventStartDate") or meta.get("_EventStartDateUTC"),
        "event_end": meta.get("_EventEndDate") or meta.get("_EventEndDateUTC"),
        "event_timezone": meta.get("_EventTimezone"),
        "all_day": meta.get("_EventAllDay"),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--base-url", required=True, help="Ej: https://tu-dominio.com")
    parser.add_argument("--per-page", type=int, default=50)
    parser.add_argument("--status", default="publish")
    parser.add_argument("--start-page", type=int, default=1)
    parser.add_argument("--max-pages", type=int, default=0, help="0 = sin límite")
    parser.add_argument("--sleep", type=float, default=1.5, help="segundos entre requests")
    parser.add_argument("--out", default="tribe_events.json")
    args = parser.parse_args()

    base_url = args.base_url.rstrip("/")
    endpoint = f"{base_url}/wp-json/wp/v2/tribe_events"

    session = requests.Session()
    session.headers.update(
        {
            "Accept": "application/json",
            "User-Agent": "EduTribeEventsFetcher/1.0 (educational; contact: you@example.com)",
        }
    )

    all_events: List[Dict[str, Any]] = []

    page = args.start_page
    total_pages = None

    while True:
        params = {
            "per_page": args.per_page,
            "page": page,
            "status": args.status,
        }

        items, tp = fetch_page(session, endpoint, params)
        if total_pages is None:
            total_pages = tp

        print(f"Página {page}/{total_pages}: {len(items)} eventos")
        for e in items:
            all_events.append(normalize_event(e))

        # Cortes de paginación
        if page >= total_pages:
            break
        if args.max_pages and (page - args.start_page + 1) >= args.max_pages:
            break

        page += 1
        time.sleep(args.sleep)

    output = {
        "source": endpoint,
        "fetched_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "count": len(all_events),
        "events": all_events,
    }

    with open(args.out, "w", encoding="utf-8") as f:
        json.dump(output, f, ensure_ascii=False, indent=2)

    print(f"Guardado: {args.out} ({len(all_events)} eventos)")
    # Aviso útil si no vinieron fechas del evento
    missing_dates = sum(1 for ev in all_events if not ev.get("event_start") and not ev.get("event_end"))
    if missing_dates:
        print(
            f"Nota: {missing_dates} eventos no traen event_start/event_end en 'meta'. "
            "Eso suele significar que el sitio no expone esos metadatos por REST."
        )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())