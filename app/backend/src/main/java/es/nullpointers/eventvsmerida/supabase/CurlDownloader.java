package es.nullpointers.eventvsmerida.supabase;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.time.Duration;
import java.util.List;
import java.util.concurrent.TimeUnit;

/**
 * Clase que se encarga de la consulta y descarga de la imagen a través del protocolo CURL con una
 * URL recibidd devolviendo la imagen en un array de bytes.
 */
public final class CurlDownloader {
    // Constructor vacío
    private CurlDownloader() {}

    /**
     * Método que con el protocolo CURL realiza la peticion HTTP a la URL de la imagen obteniendo los bytes de esta.
     * @param url URL de la imagen que se quiere descargar,
     * @param timeout Tiempo de respuesta establecido para realizar la acción.
     * @return
     */
    public static byte[] download(String url, Duration timeout) {
        // Petición CURL
        // -L sigue redirects
        // -s silent (sin barra de progreso)
        // --fail hace que curl salga con error si HTTP >= 400
        // -o - escribe el body a stdout
        List<String> cmd = List.of(
                "curl",
                "-L",
                "-s",
                "--fail",
                "--max-time", String.valueOf(Math.max(1, timeout.toSeconds())),
                "-o", "-",
                url
        );

        // Se crea un proceso para ejecutar el comando CURL.
        Process p;
        try {
            p = new ProcessBuilder(cmd)
                    .redirectErrorStream(false)
                    .start();
        } catch (IOException e) {
            throw new RuntimeException("No se pudo ejecutar curl. ¿Está instalado en el sistema?", e);
        }

        // Almacena el resultado obtenido ya sea éxito o error.
        byte[] stdout = readAllBytes(p.getInputStream());
        byte[] stderr = readAllBytes(p.getErrorStream());

        // Manejo de excepciones en caso de fallos.
        boolean terminado;
        try {
            terminado = p.waitFor(timeout.toMillis() + 5000, TimeUnit.MILLISECONDS);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            p.destroyForcibly();
            throw new RuntimeException("Interrumpido esperando a curl", e);
        }

        if (!terminado) {
            p.destroyForcibly();
            throw new RuntimeException("curl no terminó a tiempo (timeout).");
        }

        int code = p.exitValue();
        if (code != 0) {
            String err = new String(stderr);
            throw new RuntimeException("curl falló (exit=" + code + "). stderr: " + err);
        }

        if (stdout.length == 0) {
            throw new RuntimeException("curl devolvió 0 bytes para: " + url);
        }

        return stdout;
    }

    /**
     * Método que se encarga de leer el flujo de de entrada de la descarga de la imagen y los devuelve
     * en bytes para tratarlos.
     * @param in Flujo de entrada de datos.
     * @return Array de bytes la imagen.
     */
    private static byte[] readAllBytes(InputStream in) {
        try (in; ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            // Buffer de 8KB
            byte[] buf = new byte[8192];
            int n;
            while ((n = in.read(buf)) >= 0) out.write(buf, 0, n);
            return out.toByteArray();
        } catch (IOException e) {
            throw new RuntimeException("Error leyendo salida de curl", e);
        }
    }
}