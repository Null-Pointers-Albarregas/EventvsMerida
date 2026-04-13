# Programa de prueba: lee eventos-bruto.json y muestra la URL de imagen "grande" por evento
import json
import re
import requests
from bs4 import BeautifulSoup
from urllib.parse import urljoin

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

    r = requests.get(event_url, headers=headers, timeout=timeout)
    r.raise_for_status()
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

def load_json_auto(path: str):
    for enc in ("utf-8", "utf-8-sig", "cp1252", "latin-1"):
        try:
            with open(path, encoding=enc) as f:
                return json.load(f)
        except UnicodeDecodeError:
            continue
        except json.JSONDecodeError as e:
            raise RuntimeError(f"Archivo leído con {enc} pero JSON inválido: {e}")
    raise RuntimeError("No se pudo decodificar el archivo con las codificaciones probadas.")

if __name__ == "__main__":
    data = load_json_auto("eventos-bruto.json")

    for i, evento in enumerate(data.get("events", []), start=1):
        titulo = evento.get("summary", "(sin título)")
        page_url = evento.get("url")

        if not page_url:
            print(f"{i}. {titulo}\n   pagina: (sin url)\n   imagen: (no disponible)\n")
            continue

        try:
            img_url = obtener_imagen_grande(page_url, timeout=20)
        except requests.RequestException as e:
            img_url = None
            print(f"{i}. {titulo}\n   pagina: {page_url}\n   imagen: ERROR -> {e}\n")
            continue

        print(f"{i}. {titulo}\n   pagina: {page_url}\n   imagen: {img_url}\n")