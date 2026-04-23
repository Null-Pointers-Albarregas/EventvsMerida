"""
Requisitos para ejecutar este script:
   pip install playwright
   python -m playwright install chromium
"""

from urllib.parse import quote_plus, urlparse, parse_qs, unquote
import re
import time
import os
import logging
import traceback
from typing import Optional, Tuple, List, Pattern
from playwright.sync_api import sync_playwright, TimeoutError as PlaywrightTimeoutError

logger = logging.getLogger(__name__)

class MapsGeocoder:
    """Wrapper para geocodificar búsquedas en Google Maps usando Playwright.

    Usa `geocode()` para obtener (lat, lon) o `None`. Llama a `close()` al terminar.
    """
    DEFAULT_MERIDA = (38.918017, -6.342947)
    DEFAULT_NAV_TIMEOUT = 8000
    CONSENT_SELECTORS = (
        "#introAgreeButton",
        "button:has-text('Aceptar')",
        "button:has-text('Acepto')",
        "button:has-text('Aceptar todo')",
        "button:has-text('Agree')",
        "a:has-text('Aceptar')",
    )
    COORD_PATTERNS: List[Pattern] = [re.compile(p, re.S) for p in (
        r'@(-?\d+\.\d+),(-?\d+\.\d+)',
        r'!3d(-?\d+\.\d+)!4d(-?\d+\.\d+)',
        r'center=(-?\d+\.\d+),(-?\d+\.\d+)',
        r'"lat"\s*:\s*([0-9\.\-]+).*?"lng"\s*:\s*([0-9\.\-]+)',
    )]

    def __init__(self, headless: bool = True, nav_timeout: int = DEFAULT_NAV_TIMEOUT, user_agent: Optional[str] = None):
        """Inicializa Playwright, el navegador, contexto y página.

        Args:
            headless: Ejecuta el navegador en modo headless si True.
            nav_timeout: Timeout por defecto (ms) para navegación y esperas.
            user_agent: Cadena a usar como User-Agent; si None se usa una por defecto.

        Side effects:
            Inicia `sync_playwright()` y crea `self.page`. No se propagan errores de añadir cookies.
        """
        self.p = sync_playwright().start()
        self.browser = self.p.chromium.launch(headless=headless, args=["--no-sandbox", "--disable-dev-shm-usage"])
        self.context = self.browser.new_context(
            user_agent=user_agent or "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0 Safari/537.36"
        )
        try:
            self.context.add_cookies([{'name': 'CONSENT', 'value': 'YES+1', 'domain': '.google.com', 'path': '/'}])
        except Exception:
            logger.debug("No se pudo añadir cookie CONSENT", exc_info=True)
        self.page = self.context.new_page()
        self.page.set_default_navigation_timeout(nav_timeout)
        self.page.set_default_timeout(nav_timeout)

    def _goto(self, url: str, wait_until: str = 'domcontentloaded', timeout: int = 5000) -> None:
        """Navega a `url` usando `page.goto`.

        Registra timeouts y otros errores pero no relanza excepciones.

        Args:
            url: URL destino.
            wait_until: Evento de espera para `page.goto` (por ejemplo 'domcontentloaded').
            timeout: Timeout en ms para la navegación.
        """
        try:
            self.page.goto(url, wait_until=wait_until, timeout=timeout)
        except PlaywrightTimeoutError:
            logger.debug("Timeout al navegar a %s", url, exc_info=True)
        except Exception:
            logger.debug("Error goto %s", url, exc_info=True)

    def _handle_consent(self, url: str, debug: bool = False) -> bool:
        """Intenta cerrar el popup/flujo de consentimiento de Google.

        Busca selectores conocidos y hace click; si no se encuentra intenta seguir el parámetro
        de 'continue' en la query string.

        Args:
            url: URL actual de la página.
            debug: Marca de depuración (no altera comportamiento salvo logs).

        Returns:
            True si se realizó alguna acción (click o navegación alternativa), False en caso contrario.
        """
        if 'consent.google.com' not in url:
            return False

        for sel in self.CONSENT_SELECTORS:
            try:
                loc = self.page.locator(sel)

                if loc.count() > 0:
                    loc.first.click(timeout=1000)
                    time.sleep(0.25)
                    logger.debug("Clicked consent selector: %s", sel)
                    return True
            except Exception:
                logger.debug("Consent click falló para %s", sel, exc_info=True)
        
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
                logger.debug("Following consent continue -> %s", cont_url)
                self._goto(cont_url, timeout=3000)
                return True
            except Exception:
                logger.debug("Goto continue falló", exc_info=True)

        return False

    def _extract_coords_from_text(self, text: str) -> Optional[Tuple[float, float]]:
        """Extrae coordenadas (lat, lon) de un texto usando patrones predefinidos.

        Args:
            text: Texto (URL o HTML) donde buscar coordenadas.

        Returns:
            Tupla (lat, lon) si se encuentra una coincidencia, o None.
        """
        for pat in self.COORD_PATTERNS:
            m = pat.search(text)

            if m:
                try:
                    return float(m.group(1)), float(m.group(2))
                except Exception:
                    continue

        return None

    def _best_fallback(self, text: str) -> Optional[Tuple[float, float]]:
        """Fallback: encuentra cualquier par numérico y devuelve el más cercano a Mérida.

        Busca todos los pares `lat, lon` y puntúa por distancia Manhattan aproximada
        respecto a `DEFAULT_MERIDA`, devolviendo el par con menor puntuación.

        Args:
            text: Texto donde buscar pares numéricos.

        Returns:
            Tupla (lat, lon) seleccionada o None si no hay pares.
        """
        pairs = re.findall(r'(-?\d+\.\d+),\s*(-?\d+\.\d+)', text)
        if not pairs:
            return None

        def score(pair):
            try:
                return abs(float(pair[0]) - self.DEFAULT_MERIDA[0]) + abs(float(pair[1]) - self.DEFAULT_MERIDA[1])
            except Exception:
                return float('inf')

        best = min(pairs, key=score)
        return float(best[0]), float(best[1])

    def _save_debug(self, localizacion: str, html: str) -> None:
        """Guarda un screenshot y el HTML en disco para depuración.

        Los archivos se nombran como `maps_debug_<localizacion>_<timestamp>.*`.

        Args:
            localizacion: Texto de la búsqueda (usado para generar nombre de archivo).
            html: Contenido HTML a escribir en disco.
        """
        try:
            safe = re.sub(r'[^A-Za-z0-9_.-]', '_', localizacion)[:50]
            ts = time.strftime("%Y%m%d-%H%M%S")
            png = os.path.abspath(f"maps_debug_{safe}_{ts}.png")
            html_path = os.path.abspath(f"maps_debug_{safe}_{ts}.html")
            self.page.screenshot(path=png, full_page=True)
            with open(html_path, "w", encoding="utf-8") as fh:
                fh.write(html)
            logger.debug("Saved debug files: %s %s", png, html_path)
        except Exception:
            logger.debug("Fallo guardando debug artifacts", exc_info=True)

    def geocode(self, localizacion: str, max_wait: float = 4.0, poll_interval: float = 0.2, debug: bool = False) -> Optional[Tuple[float, float]]:
        """Geocodifica `localizacion` usando Google Maps y devuelve (lat, lon) o None.

        Flujo principal:
        - Valida la entrada y maneja el caso especial 'varios puntos de la ciudad'.
        - Construye la URL de búsqueda y navega.
        - Durante `max_wait` realiza polling de la URL y fragmentos de HTML buscando patrones
          de coordenadas. Intenta cerrar el popup de consentimiento si aparece.
        - Si no se encuentra coordenadas, realiza parsing del HTML final y un fallback por proximidad.
        - Si `debug` es True guarda artefactos (screenshot + HTML).

        Args:
            localizacion: Texto a geocodificar.
            max_wait: Tiempo máximo a esperar (segundos) mientras se hace polling.
            poll_interval: Intervalo entre polls (segundos).
            debug: Si True guarda archivos de depuración.

        Returns:
            Tupla (lat, lon) si se encuentra, o None en caso contrario.
        """
        if not localizacion or not localizacion.strip():
            return None
        normalized = localizacion.strip().lower()
        if 'varios puntos de la ciudad' in normalized:
            return self.DEFAULT_MERIDA

        start_url = f"https://www.google.com/maps/search/?api=1&query={quote_plus(localizacion)}"
        logger.debug("START geocode %s -> %s", localizacion, start_url)
        try:
            self._goto(start_url, timeout=5000)
            deadline = time.time() + max_wait
            previous_url = None

            while time.time() < deadline:
                url = self.page.url

                if url != previous_url:
                    logger.debug("Poll url: %s", url)
                    previous_url = url

                if self._handle_consent(url, debug=debug):
                    time.sleep(0.25)
                    continue

                coords = self._extract_coords_from_text(url)
                if coords:
                    logger.debug("Coords from url: %s", coords)
                    return coords

                try:
                    snippet = self.page.content()[:2000]
                    coords = self._extract_coords_from_text(snippet)
                    if coords:
                        logger.debug("Coords from snippet: %s", coords)
                        return coords
                except Exception:
                    logger.debug("page.content() failed", exc_info=True)

                time.sleep(poll_interval)

            final_url = self.page.url
            logger.debug("Final URL after wait: %s", final_url)
            html = self.page.content()

            coords = self._extract_coords_from_text(final_url) or self._extract_coords_from_text(html)
            if coords:
                logger.debug("Coords from final parsing: %s", coords)
                return coords

            #coords = self._best_fallback(final_url + "\n" + html)
            #if coords:
            #    logger.debug("Best fallback coords: %s", coords)
            #    return coords

            if debug:
                self._save_debug(localizacion, html)

            return None
        except Exception as e:
            logger.exception("Geocode exception: %s", e)
            return None

    def close(self) -> None:
        """Cierra recursos: contexto, navegador y detiene Playwright.

        Intenta cerrar cada recurso y suprime excepciones para asegurar limpieza segura.
        """
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