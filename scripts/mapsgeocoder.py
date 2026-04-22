from urllib.parse import quote_plus, urlparse, parse_qs, unquote
import re
import time
import os
import traceback
from playwright.sync_api import sync_playwright, TimeoutError as PlaywrightTimeoutError
from typing import Optional, Tuple

class MapsGeocoder:
    def __init__(self, headless: bool = True, nav_timeout: int = 8000):
        self.p = sync_playwright().start()
        self.browser = self.p.chromium.launch(headless=headless, args=["--no-sandbox", "--disable-dev-shm-usage"])
        self.context = self.browser.new_context(
            user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0 Safari/537.36"
        )
        try:
            # Intento rápido de evitar el popup de consentimiento
            self.context.add_cookies([{'name': 'CONSENT', 'value': 'YES+1', 'domain': '.google.com', 'path': '/'}])
        except Exception:
            pass
        self.page = self.context.new_page()
        self.page.set_default_navigation_timeout(nav_timeout)
        self.page.set_default_timeout(nav_timeout)

    def geocode(self, localizacion: str, max_wait: float = 4.0, poll_interval: float = 0.2, debug: bool = False) -> Optional[Tuple[float, float]]:
        """
        Geocodifica usando Google Maps: navega a la búsqueda y extrae coordenadas desde la URL final (@lat,lon).
        Si `debug=True` imprime información y guarda screenshot/html para inspección.
        """
        if not localizacion or not localizacion.strip():
            return None

        # Caso especial: si la localización contiene "Varios puntos de la ciudad"
        # devolver inmediatamente las coordenadas fijas de Mérida
        normalized = localizacion.strip().lower()
        if 'varios puntos de la ciudad' in normalized:
            return 38.918017, -6.342947

        consulta = f"{localizacion}"
        start_url = f"https://www.google.com/maps/search/?api=1&query={quote_plus(consulta)}"
        if debug:
            print("DEBUG start_url:", start_url)

        try:
            try:
                self.page.goto(start_url, wait_until='domcontentloaded', timeout=5000)
            except PlaywrightTimeoutError as e:
                if debug:
                    print("DEBUG initial goto timeout:", e)

            deadline = time.time() + max_wait
            previous_url = None

            while time.time() < deadline:
                url = self.page.url
                if debug and url != previous_url:
                    print("DEBUG poll url:", url)
                    previous_url = url

                # Manejo rápido de la página de consentimiento
                if 'consent.google.com' in url:
                    if debug:
                        print("DEBUG detected consent page")
                    try_selectors = (
                        "#introAgreeButton",
                        "button:has-text('Aceptar')",
                        "button:has-text('Acepto')",
                        "button:has-text('Aceptar todo')",
                        "button:has-text('Agree')",
                        "a:has-text('Aceptar')",
                    )
                    clicked = False
                    for sel in try_selectors:
                        try:
                            loc = self.page.locator(sel)
                            if loc.count() > 0:
                                loc.first.click(timeout=1000)
                                clicked = True
                                if debug:
                                    print("DEBUG clicked consent selector:", sel)
                                time.sleep(0.25)
                                break
                        except Exception as e:
                            if debug:
                                print("DEBUG click failed for selector:", sel, "->", e)
                    if not clicked:
                        # seguir el parámetro continue si existe
                        parsed = urlparse(url)
                        qs = parse_qs(parsed.query)
                        cont = None
                        for k in ('continue', 'continue_url', 'dest', 'url'):
                            if k in qs:
                                cont = qs[k][0]
                                break
                        if cont:
                            try:
                                cont_url = unquote(cont)
                                if debug:
                                    print("DEBUG following continue to:", cont_url)
                                self.page.goto(cont_url, wait_until='domcontentloaded', timeout=3000)
                            except Exception as e:
                                if debug:
                                    print("DEBUG goto continue failed:", e)

                # Comprobar patrones en la URL
                m = re.search(r'@(-?\d+\.\d+),(-?\d+\.\d+)', url)
                if m:
                    lat, lon = float(m.group(1)), float(m.group(2))
                    if debug:
                        print("DEBUG coords from url:", lat, lon)
                    return lat, lon

                m = re.search(r'!3d(-?\d+\.\d+)!4d(-?\d+\.\d+)', url)
                if m:
                    lat, lon = float(m.group(1)), float(m.group(2))
                    if debug:
                        print("DEBUG coords from url (!3d/...):", lat, lon)
                    return lat, lon

                m = re.search(r'center=(-?\d+\.\d+),(-?\d+\.\d+)', url)
                if m:
                    lat, lon = float(m.group(1)), float(m.group(2))
                    if debug:
                        print("DEBUG coords from url (center=):", lat, lon)
                    return lat, lon

                # Buscar en un snippet pequeño del HTML (rápido)
                try:
                    snippet = self.page.content()[:2000]
                    m = re.search(r'@(-?\d+\.\d+),(-?\d+\.\d+)', snippet)
                    if m:
                        lat, lon = float(m.group(1)), float(m.group(2))
                        if debug:
                            print("DEBUG coords from HTML snippet:", lat, lon)
                        return lat, lon
                except Exception as e:
                    if debug:
                        print("DEBUG page.content() failed:", e)

                time.sleep(poll_interval)

            # Después del loop, comprobar final_url y HTML en detalle
            final_url = self.page.url
            if debug:
                print("DEBUG final_url after loop:", final_url)
            html = self.page.content()

            patterns = [
                r'@(-?\d+\.\d+),(-?\d+\.\d+)',
                r'!3d(-?\d+\.\d+)!4d(-?\d+\.\d+)',
                r'center=(-?\d+\.\d+),(-?\d+\.\d+)',
                r'"lat"\s*:\s*([0-9\.\-]+).*?"lng"\s*:\s*([0-9\.\-]+)',
            ]

            for pat in patterns:
                m = re.search(pat, final_url)
                if not m:
                    m = re.search(pat, html, re.S)
                if m:
                    lat, lon = float(m.group(1)), float(m.group(2))
                    if debug:
                        print(f"DEBUG matched pattern {pat} -> {lat}, {lon}")
                    return lat, lon

            # Fallback: buscar cualquier par de coords y seleccionar el más cercano a Mérida
            all_pairs = re.findall(r'(-?\d+\.\d+),\s*(-?\d+\.\d+)', final_url + '\n' + html)
            if all_pairs:
                def score(pair):
                    try:
                        return abs(float(pair[0]) - 38.915) + abs(float(pair[1]) - (-6.34))
                    except Exception:
                        return 1e6
                best = min(all_pairs, key=score)
                lat, lon = float(best[0]), float(best[1])
                if debug:
                    print("DEBUG best fallback coords:", lat, lon)
                return lat, lon

            # Debug: guardar screenshot y HTML para inspección
            if debug:
                try:
                    safe = re.sub(r'[^A-Za-z0-9_.-]', '_', localizacion)[:50]
                    ts = time.strftime("%Y%m%d-%H%M%S")
                    png = os.path.abspath(f"maps_debug_{safe}_{ts}.png")
                    html_path = os.path.abspath(f"maps_debug_{safe}_{ts}.html")
                    try:
                        self.page.screenshot(path=png, full_page=True)
                        with open(html_path, "w", encoding="utf-8") as fh:
                            fh.write(html)
                        print("DEBUG saved screenshot to:", png)
                        print("DEBUG saved HTML to:", html_path)
                    except Exception as e:
                        print("DEBUG failed saving screenshot/html:", e)
                except Exception as e:
                    print("DEBUG debug-save error:", e)

            return None

        except Exception as e:
            if debug:
                print("DEBUG geocode exception:", e)
                traceback.print_exc()
            return None

    def close(self):
        try:
            self.context.close()
        except Exception:
            pass
        try:
            self.browser.close()
        except Exception:
            pass
        try:
            self.p.stop()
        except Exception:
            pass