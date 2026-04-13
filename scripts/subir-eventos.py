import json
import random
import re
from urllib.parse import urljoin

import requests
from bs4 import BeautifulSoup

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
    eventos_saneados = []
    num_eventos_almacenados = 0
    num_eventos_fallo = 0
    data = load_json_auto("eventos_abril_saneados.json")
    for evento in data["events"]:
        print(evento["summary"])

        id_categoria = 0
        id_usuario = random.randint(1, 3)

        match(evento["raw"]["CATEGORIES"]):
            case "Conciertos":
                id_categoria = 2
            case "Festivales":
                id_categoria = 3
            case "Cine":
                id_categoria = 4
            case "Teatro":
                id_categoria = 5
            case "Exposiciones":
                id_categoria = 6
            case "Gastronomía":
                id_categoria = 7
            case "Conferencias":
                id_categoria = 8
            case "Deportes":
                id_categoria = 9
            case _:
                id_categoria = 10

        if id_categoria == 0 or id_categoria == 10:
            continue

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


    with requests.Session() as s:
        for evento in eventos_saneados:
            try:
                resp = s.post("https://eventvsmerida.onrender.com/api/eventos/add", json=evento, timeout=10)
                resp.raise_for_status()
                print("OK:", resp.status_code, resp.text)
                num_eventos_almacenados += 1
            except requests.exceptions.HTTPError as e:
                print("Error HTTP al enviar evento:", e, "->", resp.status_code, resp.text)
                num_eventos_fallo += 1
            except requests.exceptions.Timeout:
                print("Timeout al conectar con", "https://eventvsmerida.onrender.com/api/eventos/add")
                num_eventos_fallo += 1
            except requests.exceptions.RequestException as e:
                print("Error de petición:", e)
                num_eventos_fallo += 1

    print("Eventos enviados:", eventos_saneados)
    print(f"Eventos correctos: {num_eventos_almacenados}")
    print(f"Eventos fallidos: {num_eventos_fallo}")
    print(f"Errores")

if __name__ == "__main__":
    main()
