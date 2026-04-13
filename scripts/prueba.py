import re
import requests
from bs4 import BeautifulSoup
from urllib.parse import urljoin

def obtener_imagen_grande(event_url: str, timeout: int = 20) -> str | None:
    """
    Devuelve la URL de la imagen grande de la página del evento.
    Prioridad:
      1) <a href="...jpg"><img ...></a> (original)
      2) mayor del srcset
      3) src del <img>
    """
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

    # 1) Original en el href del <a> que envuelve al <img>
    img_inside_a = container.select_one("a[href] > img")
    if img_inside_a and img_inside_a.parent and img_inside_a.parent.name == "a":
        href = img_inside_a.parent.get("href")
        if href:
            return urljoin(event_url, href)

    # 2) Mayor del srcset
    img = container.select_one("img[srcset]")
    if img and img.get("srcset"):
        best = pick_largest_from_srcset(img["srcset"])
        if best:
            return urljoin(event_url, best)

    # 3) Fallback: src
    img = container.select_one("img[src]")
    if img and img.get("src"):
        return urljoin(event_url, img["src"])

    return None