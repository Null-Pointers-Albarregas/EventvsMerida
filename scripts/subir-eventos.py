import json, random, re, sys
from urllib.parse import urljoin
from datetime import datetime

import requests
from bs4 import BeautifulSoup
from rich.console import Console
from rich.panel import Panel
from rich.progress import Progress
from rich.table import Table
from rich.text import Text

console = Console()

"""

"""
def obtener_imagen_grande(event_url: str, timeout: int = 20) -> str | None:
    """Devuelve la imagen principal del evento si existe."""
    headers = {"User-Agent": "Mozilla/5.0"}

    def pick_largest_from_srcset(srcset: str) -> str | None:
        """Elige la URL con mayor ancho del srcset."""
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

    r = requests.get(event_url, headers=headers, timeout=timeout)
    r.raise_for_status()
    soup = BeautifulSoup(r.text, "html.parser")

    container = soup.select_one(".tribe-events-single-event-description") or soup

    # Prioriza el enlace original del contenido.
    img_inside_a = container.select_one("a[href] > img")
    if img_inside_a and img_inside_a.parent and img_inside_a.parent.name == "a":
        href = img_inside_a.parent.get("href")
        if href:
            return urljoin(event_url, href)

    # Luego busca la mejor variante en srcset.
    img = container.select_one("img[srcset]")
    if img and img.get("srcset"):
        best = pick_largest_from_srcset(img["srcset"])
        if best:
            return urljoin(event_url, best)

    # Último recurso: src directo.
    img = container.select_one("img[src]")
    if img and img.get("src"):
        return urljoin(event_url, img["src"])

    return None


def load_json_auto(path):
    """Carga JSON probando varias codificaciones comunes."""
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
    """Lee eventos saneados y los publica en la API."""
    title = Text("CARGADOR DE EVENTOS - EventvsMérida", style="bold cyan", justify="center")
    console.print(Panel(title, border_style="cyan", padding=(1, 20), expand=False))
    
    eventos_saneados = []
    num_eventos_almacenados = 0
    num_eventos_fallo = 0
    
    console.print("[cyan]→[/cyan] Cargando eventos desde archivo: [yellow]" + sys.argv[1] + "[/yellow]")
    data = load_json_auto(sys.argv[1])
    total_eventos = len(data["events"])
    console.print("[green]✓[/green] Se cargaron [bold]" + str(total_eventos) + "[/bold] eventos\n")
    
    console.print("[cyan]→[/cyan] Procesando categorías...\n")
    
    with Progress() as progress:
        task = progress.add_task("[cyan]Categorizando", total=total_eventos)
        for evento in data["events"]:
            titulo = evento["summary"]
            
            id_categoria = 0
            id_usuario = random.randint(1, 3)

            match(evento["raw"]["CATEGORIES"]):
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

            eventos_saneados.append({
                "titulo": evento["summary"],
                "descripcion": evento["description"],
                "fechaInicio": evento["dtstart"],
                "fechaFin": evento["dtend"],
                "localizacion": evento["location"],
                "foto": obtener_imagen_grande(event_url=evento["url"], timeout=20),
                "idUsuario": id_usuario,
                "idCategoria": id_categoria,
            })
            progress.update(task, advance=1)
    
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
                    titulo_corto = evento['titulo'][:50]
                    console.print(f"[blue][{timestamp}][/blue] [bold]📌 {titulo_corto}[/bold]")
                    
                    resp = s.post("https://eventvsmerida.onrender.com/api/eventos/add", json=evento, timeout=10)
                    resp.raise_for_status()
                    
                    console.print(f"        [green]✓ Publicado[/green] [dim](HTTP {resp.status_code})[/dim]")
                    num_eventos_almacenados += 1
                    
                except requests.exceptions.HTTPError as e:
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
