package es.nullpointers.eventvsmerida.supabase;

import jakarta.annotation.Nullable;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientResponseException;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.web.util.UriUtils;

import java.io.IOException;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.UUID;

/**
 * Clase que se encarga de subir la imagen al bucket de Supabase una vez ha sido descargada con CURL.
 */
@Slf4j
@Component
public class SupabaseStorage {

    private final String supabaseUrl;
    private final String key;

    private final String bucket = "imagenesEvento";

    private final RestClient supabaseClient;

    // Constructor que con @Value obtiene las propiedades del application.properties
    public SupabaseStorage(
            @Value("${supabase.url}") String supabaseUrl,
            @Value("${supabase.key}") String key
    ) {
        this.supabaseUrl = supabaseUrl;
        this.key = key;

        // Construye un RestClient para hacer la petición post.
        this.supabaseClient = RestClient.builder()
                .baseUrl(supabaseUrl)
                .defaultHeader("apikey", key)
                .defaultHeader("Authorization", "Bearer " + key)
                .build();
    }

    /**
     * Método que se encarga de subir la imagen a Supabase.
     * @param urlOrigen URL de la imagen que se desea almacenar.
     * @return URL de la imagen almacenadas en el bucket.
     */
    public String subirImagen(@Nullable String urlOrigen, @Nullable MultipartFile imagen, String tituloEvento) {
        byte[] bytes = new byte[0];
        String filename;
        String contentType = "";
        String objectPath = "";
        log.info("estoy en subirImagen");
        log.error("TEST ERROR subirImagen");

        if(urlOrigen != null) {
            // Descarga con curl.
            bytes = CurlDownloader.download(urlOrigen, Duration.ofSeconds(30));

            if (bytes.length == 0) {
                throw new IllegalStateException("La URL no devolvió contenido (body vacío): " + urlOrigen);
            }

            // Genera nombre de la imagen.
            filename = normalizarNombreImagen(urlOrigen, tituloEvento, null);

            // Content-Type: se extrae según sea la extensión de la imagen.
            contentType = contentTypeFromFilename(filename);
            objectPath = filename; // raíz del bucket

        } else {
            if (imagen != null && tituloEvento != null) {
                try {
                    bytes = imagen.getBytes();

                    filename = sanitizarNombre(tituloEvento, MediaType.parseMediaType(imagen.getContentType()));
                    contentType = imagen.getContentType();
                    if (contentType == null || contentType.equals("application/octet-stream")) {
                        contentType = contentTypeFromFilename(filename);
                    }                    objectPath = filename; // raíz del bucket
                } catch (IOException e) {
                    throw new IllegalStateException("Error al leer el contenido de la imagen: " + imagen.getOriginalFilename(), e);
                }
            }
        }
        // Normaliza la url del path para evitar caracteres raros.
        String encodedPath = UriUtils.encodePath(objectPath, StandardCharsets.UTF_8);

        // Petición POST para almacenar la imagen
        try {
            supabaseClient.post()
                    .uri(uriBuilder -> uriBuilder
                            .path("/storage/v1/object/{bucket}/{path}")
                            .queryParam("upsert", true)
                            .build(Map.of("bucket", bucket, "path", encodedPath)))
                    .contentType(MediaType.parseMediaType(contentType))
                    .body(bytes)
                    .retrieve()
                    .toBodilessEntity();
        } catch (HttpClientErrorException e) {
            String body = e.getResponseBodyAsString();
            boolean duplicate = body != null && body.contains("\"error\":\"Duplicate\"");
            if (duplicate) {
                throw new ResponseStatusException(HttpStatus.CONFLICT, "Esta imagen ya está almacenada", e);
            }
            throw e;
        }

        return supabaseUrl + "/storage/v1/object/public/" + bucket + "/" + encodedPath;
    }

    /**
     * Método para obtener el nombre del fichero o generar uno nuevo para evitar valores nulos.
     * @param url URL de la imagen de origen.
     * @param mt Tipo de imagen.
     * @return Nombre de la imagen.
     */
    private static String normalizarNombreImagen(String url, String tituloEvento, MediaType mt) {
        String nombreFichero = "";

        if (url != null && !url.isBlank()) {
            try {
                String path = URI.create(url).getPath();
                String last = (path == null) ? "" : path.substring(path.lastIndexOf('/') + 1);
                if (!last.isBlank() && last.contains(".")) {
                    nombreFichero = last;
                } else {
                    nombreFichero = url;
                }
            } catch (IllegalArgumentException e) {
                nombreFichero = url;
            }
        }

        if (nombreFichero == null || nombreFichero.isBlank()) {
            String ext = extensionFromMediaType(mt);
            nombreFichero = "file-" + Instant.now().toEpochMilli() + "-" + UUID.randomUUID() + ext;
        }

        return sanitizarNombre(tituloEvento, mt);
    }

    /**
     * Método para sanitizar el tituloEvento de la imagen, evitando espacios y caracteres no seguros y generando un tituloEvento válido.
     * @param tituloEvento Nombre de la imagen a sanetizar.
     * @param mt Tipo de imagen.
     * @return Título de la imagen sanitizado.
     */
    private static String sanitizarNombre(String tituloEvento, MediaType mt) {
        String nombreImagen = (tituloEvento == null) ? "" : tituloEvento.trim();

        // Separar base + extensión.
        int indice = nombreImagen.lastIndexOf('.');
        String base = indice > 0 ? nombreImagen.substring(0, indice) : nombreImagen;
        String extension = indice > 0 ? nombreImagen.substring(indice).toLowerCase() : extensionFromMediaType(mt);

        // Reemplazar espacios por '-'
        base = base.replaceAll("\\s+", "-");

        // Limpia los caracteres no seguros en rutas.
        base = base.replaceAll("[^a-zA-Z0-9._-]", "-");

        // Evitar tituloEvento vacío
        if (base.isBlank()) {
            base = "file-" + Instant.now().toEpochMilli() + "-" + UUID.randomUUID();
        }

        return base + extension;
    }

    /**
     * Método que en función de como termine la extensión, sacamos el tipo de imagen
     * la cual se incluye en las cabeceras a la hora de subir la imagen para indicarle a Suoabase
     * el tipo de imagen.
     * @param filename Imagen.
     * @return Tipo de imagen.
     */
    private static String contentTypeFromFilename(String filename) {
        String f = filename.toLowerCase();
        if (f.endsWith(".png")) return "image/png";
        if (f.endsWith(".jpg") || f.endsWith(".jpeg")) return "image/jpeg";
        return "application/octet-stream";
    }

    /**
     * Método que devuelve la extensión del fichero en función del tipo de imagen.
     * @param mt Tipo de imagen.
     * @return Extensión que va a utilizar la imagen.
     */
    private static String extensionFromMediaType(MediaType mt) {
        if (mt == null) return "";
        if (MediaType.IMAGE_PNG.includes(mt)) return ".png";
        if (MediaType.IMAGE_JPEG.includes(mt)) return ".jpg";
        return "";
    }
}