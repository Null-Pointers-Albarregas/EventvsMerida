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
    public String subirImagen(@Nullable String urlOrigen, @Nullable MultipartFile imagen, @Nullable String tituloEvento) {
        byte[] bytes = new byte[0];
        String filename;
        String contentType = "";
        String objectPath = "";
        log.info("estoy en subirImagen");
        log.error("TEST ERROR subirImagen");

        if(urlOrigen != null) {
            log.info("entra en el if");
            // Descarga con curl.
            bytes = CurlDownloader.download(urlOrigen, Duration.ofSeconds(30));

            if (bytes.length == 0) {
                throw new IllegalStateException("La URL no devolvió contenido (body vacío): " + urlOrigen);
            }

            // Genera nombre de la imagen.
            filename = filenameFromUrlOrGenerate(urlOrigen, null);

            // Content-Type: se extrae según sea la extensión de la imagen.
            contentType = contentTypeFromFilename(filename);
            objectPath = filename; // raíz del bucket

        } else {
            log.info("entra en el else");
            if (imagen != null && tituloEvento != null) {
                try {
                    bytes = imagen.getBytes();

                    filename = imagen.getOriginalFilename();
                    log.info("Filename--->{}", filename);
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
     * Méotodo para obtener el nombre del fichero o generar uno nuevo para evitar valores nulos.
     * @param sourceUrl URL de la imagen de origen.
     * @param mt Tipo de imagen.
     * @return Nombre de la imagen.
     */
    private static String filenameFromUrlOrGenerate(String sourceUrl, MediaType mt) {
        String path = URI.create(sourceUrl).getPath();
        String last = (path == null) ? "" : path.substring(path.lastIndexOf('/') + 1);

        if (last != null && !last.isBlank() && last.contains(".")) {
            return last;
        }

        String ext = extensionFromMediaType(mt);
        return "file-" + Instant.now().toEpochMilli() + "-" + UUID.randomUUID() + ext;
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