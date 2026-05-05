"""
subir-eventos.py — Carga eventos saneados a la API de EventvsMérida.

Uso:
    python subir-eventos.py eventos-saneados.json

Requisitos:
    pip install requests beautifulsoup4 rich
    pip install python-dotenv

Nota:
    Para geocoding el script usa la clase `MapsGeocoder` en scripts/mapsgeocoder.py (Playwright).
"""

import argparse
import json
import logging
import os
import random
import re
import sys
import time
from pathlib import Path
from typing import Any, Dict, Optional
from urllib.parse import urljoin, urlparse
from datetime import datetime

import requests
from bs4 import BeautifulSoup
from rich.console import Console
from rich.panel import Panel
from rich.progress import Progress
from rich.table import Table
from rich.text import Text

try:
    from dotenv import load_dotenv
except Exception:  # pragma: no cover - optional dependency for local .env use
    load_dotenv = None

console = Console()
logger = logging.getLogger(__name__)


def pick_largest_from_srcset(srcset: str) -> Optional[str]:
    """Selecciona la URL de mayor anchura declarada en un `srcset`."""
    best_url: Optional[str] = None
    best_w = -1
    for part in (p.strip() for p in srcset.split(",")):
        if not part:
            continue
        bits = part.split()
        url = bits[0]
        w = 0
        if len(bits) > 1:
            m = re.match(r"(\d+)w", bits[1])
            if m:
                w = int(m.group(1))
        if w > best_w:
            best_w = w
            best_url = url
    return best_url


def obtener_imagen_grande(event_url: str, session: Optional[requests.Session] = None, timeout: int = 20) -> Optional[str]:
    """Intenta obtener una imagen representativa grande desde la página del evento.

    Estrategia:
      - Busca un <img> dentro de un <a> (si el enlace apunta a la imagen grande).
      - Busca `img[srcset]` y selecciona la URL con mayor ancho.
      - Busca `img[src]` como fallback.

    Args:
        event_url: URL de la página del evento.
        session: `requests.Session` opcional para reutilizar conexiones.
        timeout: timeout en segundos para la petición HTTP.

    Returns:
        URL absoluta de la imagen si se encuentra, o None.
    """
    headers = {"User-Agent": "Mozilla/5.0"}
    try:
        if session:
            r = session.get(event_url, headers=headers, timeout=timeout)
        else:
            r = requests.get(event_url, headers=headers, timeout=timeout)
        r.raise_for_status()
    except Exception as e:
        logger.debug("Error fetching %s: %s", event_url, e)
        return None

    soup = BeautifulSoup(r.text, "html.parser")
    container = soup.select_one(".tribe-events-single-event-description") or soup

    # Si hay una img dentro de un enlace, devolver href del enlace (a veces enlaza la imagen grande)
    img_inside_a = container.select_one("a[href] > img")
    if img_inside_a and img_inside_a.parent and img_inside_a.parent.name == "a":
        href = img_inside_a.parent.get("href")
        if href:
            return urljoin(event_url, href)

    # Buscar srcset y elegir la mejor
    img = container.select_one("img[srcset]")
    if img and img.get("srcset"):
        best = pick_largest_from_srcset(img["srcset"])
        if best:
            return urljoin(event_url, best)

    # Fallback a src
    img = container.select_one("img[src]")
    if img and img.get("src"):
        return urljoin(event_url, img["src"])

    return None


def load_json_auto(path: Path | str) -> Any:
    """Carga un JSON probando varias codificaciones comunes.

    Args:
        path: Ruta al fichero JSON.

    Returns:
        El objeto Python resultante del `json.load`.
    """
    p = Path(path)
    for enc in ("utf-8", "utf-8-sig", "cp1252", "latin-1"):
        try:
            with p.open(encoding=enc) as f:
                return json.load(f)
        except UnicodeDecodeError:
            continue
        except json.JSONDecodeError as e:
            raise RuntimeError(f"Archivo leído con {enc} pero JSON inválido: {e}")
    raise RuntimeError("No se pudo decodificar el archivo con las codificaciones probadas.")


def build_auth_url(api_url: str) -> str:
    parsed = urlparse(api_url)
    base = f"{parsed.scheme}://{parsed.netloc}"
    return urljoin(base, "/api/auth")


def login_admin(session: requests.Session, auth_url: str, email: str, password: str) -> bool:
    payload = {"email": email, "password": password}
    resp = session.post(
        f"{auth_url}/login",
        params={"admin": "true"},
        json=payload,
        timeout=10,
    )
    if resp.status_code != 200:
        console.print(f"[red]✗ Login fallido[/red] [dim](HTTP {resp.status_code})[/dim]")
        return False

    sess = session.get(f"{auth_url}/session", timeout=10)
    if sess.status_code != 200:
        console.print(f"[red]✗ Sesion no valida[/red] [dim](HTTP {sess.status_code})[/dim]")
        return False

    return True


def main(argv: Optional[list] = None) -> int:
    """Flujo principal: lee eventos saneados, geocodifica y los publica en la API.

    Args:
        argv: Lista de argumentos (por defecto sys.argv[1:]).

    Returns:
        Código de salida (0 = OK).
    """
    if load_dotenv is None:
        console.print("[red]✗ Falta dependencia: python-dotenv[/red]")
        console.print("    Instala con: pip install python-dotenv")
        return 2

    load_dotenv()

    parser = argparse.ArgumentParser(description="Sube eventos saneados a la API EventvsMérida")
    parser.add_argument("input", help="JSON de eventos saneados (output de saneador-caracteres.py)")
    parser.add_argument("--api-url", default="https://eventvsmerida-x2t1.onrender.com/api/eventos/add", help="URL API para publicar eventos")
    parser.add_argument("--email", default=os.getenv("EVENTVSMERIDA_EMAIL"), help="Email admin (o env EVENTVSMERIDA_EMAIL)")
    parser.add_argument("--password", default=os.getenv("EVENTVSMERIDA_PASSWORD"), help="Password admin (o env EVENTVSMERIDA_PASSWORD)")
    args = parser.parse_args(argv)

    logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")

    input_path = Path(args.input)
    if not input_path.exists():
        console.print(f"[red]Archivo no encontrado:[/red] {input_path}")
        return 2

    try:
        data = load_json_auto(input_path)
    except Exception as e:
        console.print(f"[red]✗ Error cargando JSON:[/red] {e}")
        return 2

    total_eventos = len(data.get("events", []))
    console.print("[green]✓[/green] Se cargaron [bold]" + str(total_eventos) + "[/bold] eventos\n")

    # Intentar inicializar MapsGeocoder si está disponible (opcional)
    geocoder = None
    try:
        from mapsgeocoder import MapsGeocoder  # type: ignore
        try:
            geocoder = MapsGeocoder(headless=True, nav_timeout=8000)
        except Exception as e:
            console.print(f"[yellow]⚠️ No se pudo iniciar MapsGeocoder (se seguirá sin geocoding):[/yellow] {e}")
            geocoder = None
    except Exception:
        console.print("[yellow]⚠️ mapsgeocoder no disponible — se omite geocoding.[/yellow]")

    console.print("[cyan]→[/cyan] Procesando localizaciones...\n")

    eventos_saneados: list[Dict[str, Any]] = []
    num_eventos_almacenados = 0
    num_eventos_fallo = 0

    with requests.Session() as session:
        session.headers.update({"User-Agent": "Mozilla/5.0"})
        auth_url = build_auth_url(args.api_url)
        if not args.email or not args.password:
            console.print("[red]✗ Faltan credenciales de admin (email/password).[/red]")
            return 2
        if not login_admin(session, auth_url, args.email, args.password):
            return 2
        with Progress() as progress:
            task = progress.add_task("[cyan]Localizando", total=total_eventos)
            for evento in data.get("events", []):
                titulo = evento.get("summary", "") or ""
                progress.update(task, description="Localizando")
                id_categoria = 0
                id_usuario = random.randint(1, 5)

                localizacion = evento.get("location", "") or ""
                latitud: Optional[float] = None
                longitud: Optional[float] = None

                if localizacion and geocoder:
                    coords = None
                    try:
                        coords = geocoder.geocode(localizacion, max_wait=6.0, poll_interval=0.25)
                        if not coords:
                            coords = geocoder.geocode(localizacion, max_wait=8.0, poll_interval=0.35)
                    except Exception as e:
                        coords = None
                        logger.warning("Error geocoding %s: %s", localizacion, e)

                    if coords:
                        latitud, longitud = coords

                    if coords:
                        linea = (
                            f"    Título: {titulo[:60]} | [green]📍 Coordenadas:[/green] {latitud}, {longitud}"
                        )
                    else:
                        linea = (
                            f"    Título: {titulo[:60]} | "
                            f"[yellow]⚠️ No se pudo geocodificar (Google Maps):[/yellow] {localizacion}"
                        )
                    progress.console.print(linea)

                    time.sleep(0.15)
                else:
                    progress.console.print(f"    Título: {titulo[:60]}")

                raw_cats = evento.get("raw", {}).get("CATEGORIES")
                if isinstance(raw_cats, dict):
                    raw_id = raw_cats.get("id")
                    if raw_id is not None:
                        try:
                            id_categoria = int(raw_id)
                        except Exception:
                            id_categoria = 12
                elif isinstance(raw_cats, str):
                    id_categoria = 12

                eventos_saneados.append(
                    {
                        "titulo": titulo,
                        "descripcion": evento.get("description", "") or "",
                        "fechaInicio": evento.get("dtstart", ""),
                        "fechaFin": evento.get("dtend", ""),
                        "localizacion": localizacion,
                        "latitud": latitud,
                        "longitud": longitud,
                        "foto": obtener_imagen_grande(event_url=evento.get("url", "") or "", session=session, timeout=20),
                        "idUsuario": id_usuario,
                        "idCategoria": id_categoria,
                    }
                )
                print(eventos_saneados[-1])
                print()
                progress.update(task, advance=1)

        if geocoder:
            try:
                geocoder.close()
            except Exception:
                pass

        console.print()
        encabezado = Text("ENVIANDO EVENTOS A API", style="bold green")
        console.print(Panel(encabezado, border_style="green"))
        console.print()

        with Progress() as progress:
            task = progress.add_task("[green]Subiendo", total=len(eventos_saneados))
            for evento in eventos_saneados:
                try:
                    timestamp = datetime.now().strftime("%H:%M:%S")
                    titulo_corto = (evento.get("titulo") or "")[:50]
                    console.print(f"[blue][{timestamp}][/blue] [bold]📌 {titulo_corto}[/bold]")

                    evento_payload = json.dumps(evento, ensure_ascii=False)
                    print(evento_payload)
                    resp = session.post(
                        args.api_url,
                        data={"evento": evento_payload},
                        files={"imagen": ("", b"", "application/octet-stream")},
                        timeout=10,
                    )
                    resp.raise_for_status()

                    if resp.status_code != 201:
                        console.print(
                            f"        [red]✗ Respuesta no válida[/red] [dim](HTTP {resp.status_code})[/dim]"
                        )
                        num_eventos_fallo += 1
                    else:
                        console.print(f"        [green]✓ Publicado[/green] [dim](HTTP {resp.status_code})[/dim]")
                        num_eventos_almacenados += 1

                except requests.exceptions.HTTPError:
                    console.print(f"        [red]✗ Error HTTP[/red] [dim](HTTP {resp.status_code})[/dim]")
                    num_eventos_fallo += 1
                except requests.exceptions.Timeout:
                    console.print(f"        [red]✗ Timeout[/red] [dim](servidor tardó demasiado)[/dim]")
                    num_eventos_fallo += 1
                except requests.exceptions.RequestException as e:
                    console.print(f"        [red]✗ Error de conexión[/red] [dim]({str(e)[:40]})[/dim]")
                    num_eventos_fallo += 1

                progress.update(task, advance=1)

    console.print()
    porcentaje_exito = (num_eventos_almacenados / len(eventos_saneados) * 100) if eventos_saneados else 0

    tabla = Table(title="RESUMEN FINAL", border_style="cyan", show_header=True)
    tabla.add_column("Métrica", style="cyan")
    tabla.add_column("Valor", style="bold")
    tabla.add_row("Eventos enviados", f"[green]{num_eventos_almacenados}[/green]/{len(eventos_saneados)}")
    tabla.add_row("Eventos fallidos", f"[red]{num_eventos_fallo}[/red]/{len(eventos_saneados)}")
    tabla.add_row("Tasa de éxito", f"[yellow]{porcentaje_exito:.1f}%[/yellow]")

    console.print(tabla)
    console.print()

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
