#!/usr/bin/env python3
import json
import random
import re
import sys
import time
from urllib.parse import urljoin
from datetime import datetime
from typing import Optional, Tuple

import requests
from bs4 import BeautifulSoup
from rich.console import Console
from rich.panel import Panel
from rich.progress import Progress
from rich.table import Table
from rich.text import Text

console = Console()


def obtener_imagen_grande(event_url: str, timeout: int = 20) -> str | None:
    headers = {"User-Agent": "Mozilla/5.0"}

    def pick_largest_from_srcset(srcset: str) -> str | None:
        best_url, best_w = None, -1
        for part in (p.strip() for p in srcset.split(",")):
            if not part:
                continue
            bits = part.split()
            u = bits[0]
            w = 0
            if len(bits) > 1:
                m = re.match(r"(\d+)w", bits[1])
                if m:
                    w = int(m.group(1))
            if w > best_w:
                best_url, best_w = u, w
        return best_url

    try:
        r = requests.get(event_url, headers=headers, timeout=timeout)
        r.raise_for_status()
    except Exception:
        return None

    soup = BeautifulSoup(r.text, "html.parser")
    container = soup.select_one(".tribe-events-single-event-description") or soup

    img_inside_a = container.select_one("a[href] > img")
    if img_inside_a and img_inside_a.parent and img_inside_a.parent.name == "a":
        href = img_inside_a.parent.get("href")
        if href:
            return urljoin(event_url, href)

    img = container.select_one("img[srcset]")
    if img and img.get("srcset"):
        best = pick_largest_from_srcset(img["srcset"])
        if best:
            return urljoin(event_url, best)

    img = container.select_one("img[src]")
    if img and img.get("src"):
        return urljoin(event_url, img["src"])

    return None


def load_json_auto(path):
    for enc in ("utf-8", "utf-8-sig", "cp1252", "latin-1"):
        try:
            with open(path, encoding=enc) as f:
                return json.load(f)
        except UnicodeDecodeError:
            continue
        except json.JSONDecodeError as e:
            raise RuntimeError(f"Archivo leído con {enc} pero JSON inválido: {e}")
    raise RuntimeError("No se pudo decodificar el archivo con las codificaciones probadas.")


def main():
    if len(sys.argv) < 2:
        print("Uso: python subir-eventos.py <eventos-saneados.json>")
        sys.exit(1)

    archivo = sys.argv[1]

    title = Text("CARGADOR DE EVENTOS - EventvsMérida", style="bold cyan", justify="center")
    console.print(Panel(title, border_style="cyan", padding=(1, 20), expand=False))

    try:
        data = load_json_auto(archivo)
    except Exception as e:
        console.print(f"[red]✗ Error cargando JSON:[/red] {e}")
        sys.exit(1)

    total_eventos = len(data.get("events", []))
    console.print("[green]✓[/green] Se cargaron [bold]" + str(total_eventos) + "[/bold] eventos\n")

    # IMPORTAR E INICIAR MapsGeocoder (Playwright). Si falla, salir.
    try:
        from mapsgeocoder import MapsGeocoder
    except Exception as e:
        console.print(f"[red]✗ mapsgeocoder no encontrado: {e}[/red]")
        console.print("[red]Este script requiere Playwright y la clase MapsGeocoder en scripts/mapsgeocoder.py[/red]")
        sys.exit(1)

    try:
        geocoder = MapsGeocoder(headless=True, nav_timeout=8000)
    except Exception as e:
        console.print(f"[red]✗ No se pudo iniciar MapsGeocoder: {e}[/red]")
        sys.exit(1)

    console.print("[cyan]→[/cyan] MapsGeocoder iniciado (Playwright) — usando solo Google Maps para geocoding\n")

    eventos_saneados = []
    num_eventos_almacenados = 0
    num_eventos_fallo = 0

    console.print("[cyan]→[/cyan] Procesando categorías...\n")

    with Progress() as progress:
        task = progress.add_task("[cyan]Categorizando", total=total_eventos)
        for evento in data.get("events", []):
            titulo = evento.get("summary", "")
            id_categoria = 0
            id_usuario = random.randint(1, 5)

            match evento.get("raw", {}).get("CATEGORIES", ""):
                case "Conciertos y Música":
                    id_categoria = 1
                case "Festivales y Ferias":
                    id_categoria = 2
                case "Cine y Teatro":
                    id_categoria = 3
                case "Exposiciones y Arte":
                    id_categoria = 4
                case "Gastronomía":
                    id_categoria = 5
                case "Conferencias, Talleres y Cursos":
                    id_categoria = 6
                case "Deportes y Actividad Física":
                    id_categoria = 7
                case "Fiestas y Vida Nocturna":
                    id_categoria = 8
                case "Familia e Infantil":
                    id_categoria = 9
                case "Tecnología y Ciencia":
                    id_categoria = 10
                case "Solidaridad y Causas Sociales":
                    id_categoria = 11
                case _:
                    id_categoria = 12

            localizacion = evento.get("location", "") or ""
            latitud = None
            longitud = None

            if localizacion:
                coords = None
                try:
                    # usar el geocoder (reutiliza el navegador). Ajusta max_wait/poll_interval si quieres más paciencia/velocidad.
                    coords = geocoder.geocode(localizacion, max_wait=4.0, poll_interval=0.18)
                except Exception as e:
                    coords = None
                    console.print(f"[yellow]⚠️ Error geocoding con MapsGeocoder:[/yellow] {e}")

                if coords:
                    latitud, longitud = coords
                    console.print(f"[green]📍 Coordenadas:[/green] {latitud}, {longitud}")
                else:
                    console.print(f"[yellow]⚠️ No se pudo geocodificar (Google Maps):[/yellow] {localizacion}")

                # ligera pausa para no saturar
                time.sleep(0.15)

            eventos_saneados.append(
                {
                    "titulo": titulo,
                    "descripcion": evento.get("description", "") or "",
                    "fechaInicio": evento.get("dtstart", ""),
                    "fechaFin": evento.get("dtend", ""),
                    "localizacion": localizacion,
                    "latitud": latitud,
                    "longitud": longitud,
                    "foto": obtener_imagen_grande(event_url=evento.get("url", ""), timeout=20),
                    "idUsuario": id_usuario,
                    "idCategoria": id_categoria,
                }
            )
            progress.update(task, advance=1)

    # Cerrar geocoder
    try:
        geocoder.close()
    except Exception:
        pass

    console.print()
    encabezado = Text("ENVIANDO EVENTOS A API", style="bold green")
    console.print(Panel(encabezado, border_style="green"))
    console.print()

    with requests.Session() as s:
        with Progress() as progress:
            task = progress.add_task("[green]Subiendo", total=len(eventos_saneados))
            for evento in eventos_saneados:
                try:
                    timestamp = datetime.now().strftime("%H:%M:%S")
                    titulo_corto = (evento.get("titulo") or "")[:50]
                    console.print(f"[blue][{timestamp}][/blue] [bold]📌 {titulo_corto}[/bold]")

                    resp = s.post("https://eventvsmerida.onrender.com/api/eventos/add", json=evento, timeout=10)
                    resp.raise_for_status()

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


if __name__ == "__main__":
    main()