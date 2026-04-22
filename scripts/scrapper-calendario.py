"""
Descarga un feed iCal (ICS) y lo convierte a JSON.

El calendario suele exponer iCal en URLs como:
  https://TU_DOMINIO/events/?ical=1
  https://TU_DOMINIO/events/list/?ical=1

Este script:
- Descarga el .ics
- Parsear VEVENT (DTSTART/DTEND/SUMMARY/DESCRIPTION/LOCATION/URL/UID)
- Convierte fechas a ISO 8601
- Exporta a JSON
Requisitos:
  pip install requests

Ejecutar:
    python scrapper-calendario.py --ics-url "https://TU_DOMINIO/events/?ical=1" --out eventos-bruto.json
    Ejemplo url: https://merida.es/agenda/lista/?tribe-bar-date=2026-02-01&ical=1
"""

from __future__ import annotations

import argparse
import json
import re
from dataclasses import dataclass, asdict
from datetime import datetime, timezone
from typing import Dict, List, Optional, Tuple

import requests

try:
    from zoneinfo import ZoneInfo
except ImportError:  # Python < 3.9
    ZoneInfo = None  # type: ignore[assignment]


@dataclass
class Event:
    uid: Optional[str]
    summary: Optional[str]
    description: Optional[str]
    location: Optional[str]
    url: Optional[str]
    dtstart: Optional[str]   # ISO 8601
    dtend: Optional[str]     # ISO 8601
    timezone: Optional[str]
    raw: Dict[str, str]      # campos originales útiles para depurar


def resolve_tzinfo(tzid: Optional[str]):
    """Resuelve un TZID iCal a tzinfo estándar (zoneinfo)."""
    if not tzid or ZoneInfo is None:
        return None
    try:
        return ZoneInfo(tzid)
    except Exception:
        return None


def unfold_ical_lines(text: str) -> List[str]:
    """Une líneas plegadas del formato iCal."""
    text = text.replace("\r\n", "\n").replace("\r", "\n")
    lines = text.split("\n")
    out: List[str] = []
    for line in lines:
        if not line:
            out.append(line)
            continue
        if line.startswith((" ", "\t")) and out:
            out[-1] += line[1:]
        else:
            out.append(line)
    return out


def parse_ical_datetime(value: str, params: Dict[str, str], default_tz: Optional[str]) -> Tuple[Optional[datetime], Optional[str]]:
    """Convierte fechas iCal a datetime con o sin zona horaria."""
    value = value.strip()
    tzid = params.get("TZID") or default_tz

    # All-day: YYYYMMDD
    if re.fullmatch(r"\d{8}", value):
        dt = datetime.strptime(value, "%Y%m%d")
        # all-day sin tz, lo dejamos naive (sin zona)
        return dt, tzid

    # UTC: termina en Z
    if value.endswith("Z"):
        dt = datetime.strptime(value, "%Y%m%dT%H%M%SZ").replace(tzinfo=timezone.utc)
        return dt, "UTC"

    # Local con hora
    if re.fullmatch(r"\d{8}T\d{6}", value):
        dt = datetime.strptime(value, "%Y%m%dT%H%M%S")
        tzinfo = resolve_tzinfo(tzid)
        if tzinfo is not None:
            dt = dt.replace(tzinfo=tzinfo)
        return dt, tzid

    return None, tzid


def parse_ics(text: str) -> List[Event]:
    lines = unfold_ical_lines(text)

    events: List[Event] = []
    in_event = False
    current: Dict[str, str] = {}
    current_params: Dict[str, Dict[str, str]] = {}
    calendar_tz: Optional[str] = None

    def finish_event():
        nonlocal current, current_params
        raw = dict(current)

        def get(key: str) -> Optional[str]:
            return current.get(key)

        # Usa la zona horaria global del calendario si existe.
        tz_guess = calendar_tz

        dtstart_raw = get("DTSTART")
        dtend_raw = get("DTEND")

        dtstart_dt = None
        dtend_dt = None
        tz_used = None

        # Lee DTSTART y DTEND del evento.
        if dtstart_raw:
            dtstart_dt, tz_used = parse_ical_datetime(dtstart_raw, current_params.get("DTSTART", {}), tz_guess)
        if dtend_raw:
            dtend_dt, _ = parse_ical_datetime(dtend_raw, current_params.get("DTEND", {}), tz_guess)

        def to_iso(dt: Optional[datetime]) -> Optional[str]:
            """Devuelve fecha simple o ISO sin offset de zona horaria."""
            if dt is None:
                return None
            # Eliminar cualquier tzinfo para evitar offsets
            dt_naive = dt.replace(tzinfo=None) if dt.tzinfo else dt
            # All-day: solo fecha (sin hora, sin timezone)
            is_allday = dt_naive.hour == 0 and dt_naive.minute == 0 and dt_naive.second == 0
            if is_allday:
                return dt_naive.strftime("%Y-%m-%d")
            # Con hora: devolver ISO sin offset
            return dt_naive.strftime("%Y-%m-%dT%H:%M:%S")

        events.append(
            Event(
                uid=get("UID"),
                summary=get("SUMMARY"),
                description=get("DESCRIPTION"),
                location=get("LOCATION"),
                url=get("URL"),
                dtstart=to_iso(dtstart_dt),
                dtend=to_iso(dtend_dt),
                timezone=tz_used,
                raw=raw,
            )
        )

        current = {}
        current_params = {}

    for line in lines:
        if line == "BEGIN:VEVENT":
            in_event = True
            current = {}
            current_params = {}
            continue
        if line == "END:VEVENT":
            if in_event:
                finish_event()
            in_event = False
            continue

        # Timezone global del calendario (fuera de VEVENT)
        if not in_event:
            # Ej: X-WR-TIMEZONE:Europe/Madrid
            if line.startswith("X-WR-TIMEZONE:"):
                calendar_tz = line.split(":", 1)[1].strip() or None
            continue

        # Dentro de VEVENT: parsear KEY(;PARAM=VAL)*:VALUE
        if ":" not in line:
            continue

        left, value = line.split(":", 1)
        parts = left.split(";")
        key = parts[0].strip().upper()

        params: Dict[str, str] = {}
        for p in parts[1:]:
            if "=" in p:
                k, v = p.split("=", 1)
                params[k.strip().upper()] = v.strip()

        current[key] = value.strip()
        if params:
            current_params[key] = params

    return events


def main() -> int:
    """Descarga el ICS y lo guarda convertido a JSON."""
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--ics-url",
        required=True,
        help="Ej: https://tu-dominio.com/events/?ical=1",
    )
    parser.add_argument("--out", default="events_from_ics.json")
    parser.add_argument("--timeout", type=int, default=30)
    args = parser.parse_args()

    r = requests.get(
        args.ics_url,
        headers={
            "User-Agent": "EduICSFetcher/1.0 (educational; contact: you@example.com)",
            "Accept": "text/calendar, text/plain, */*",
        },
        timeout=args.timeout,
    )
    r.raise_for_status()

    # Manejo BOM por si el servidor lo añade también aquí
    text = r.content.decode("utf-8-sig", errors="replace")

    events = parse_ics(text)

    payload = {
        "source": args.ics_url,
        "fetched_at": datetime.now(timezone.utc).isoformat(),
        "count": len(events),
        "events": [asdict(e) for e in events],
    }

    with open(args.out, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=2)

    print(f"OK: {args.out} ({len(events)} eventos)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())