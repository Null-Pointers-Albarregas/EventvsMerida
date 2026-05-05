package es.nullpointers.eventvsmerida.supabase;

import jakarta.annotation.Nullable;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.RestClient;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.web.util.UriUtils;

import java.io.IOException;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.Map;

/**
 * Clase que se encarga de subir la imagen al bucket de Supabase una vez ha sido descargada con CURL.
 */
@Slf4j
@Component
public class SupabaseStorage {

    private final String supabaseUrl;
    private final RestClient supabaseClient;
    private final String bucketEventos = "imagenesEvento";
    private final String bucketUsuarios = "imagenesPerfil";

    // Constructor que con @Value obtiene las propiedades del application.properties
    public SupabaseStorage(@Value("${supabase.url}") String supabaseUrl, @Value("${supabase.key}") String key) {
        this.supabaseUrl = supabaseUrl;

        // Construye un RestClient para hacer la petición post.
        this.supabaseClient = RestClient.builder()
                .baseUrl(supabaseUrl)
                .defaultHeader("apikey", key)
                .defaultHeader("Authorization", "Bearer " + key)
                .build();
    }

    /**
     * Método que se encarga de subir la imagen a Supabase.
     *
     * @param urlOrigen URL de la imagen que se desea almacenar.
     * @return URL de la imagen almacenadas en el bucket.
     */
    public String subirImagenEvento(@Nullable String urlOrigen, @Nullable MultipartFile imagen, String tituloEvento) {
        byte[] bytes = new byte[0];
        String filename;
        String contentType = "";
        String objectPath = "";

        if (urlOrigen != null) {
            // Descarga con curl.
            bytes = CurlDownloader.download(urlOrigen, Duration.ofSeconds(30));

            if (bytes.length == 0) {
                throw new IllegalStateException("La URL no devolvió contenido (body vacío): " + urlOrigen);
            }

            // Genera nombre de la imagen.
            filename = obtenerNombreImagenDesdeUrl(urlOrigen, tituloEvento);

            // Content-Type: se extrae según sea la extensión de la imagen.
            contentType = contentTypeFromFilename(filename);
            objectPath = filename; // raíz del bucket

        } else {
            if (imagen != null && tituloEvento != null) {
                try {
                    bytes = imagen.getBytes();

                    filename = construirNombreImagenEvento(tituloEvento, imagen.getOriginalFilename());
                    contentType = imagen.getContentType();
                    if (contentType == null || contentType.equals("application/octet-stream")) {
                        contentType = contentTypeFromFilename(filename);
                    }
                    objectPath = filename; // raíz del bucket
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
                            .build(Map.of("bucket", bucketEventos, "path", encodedPath)))
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

        return supabaseUrl + "/storage/v1/object/public/" + bucketEventos + "/" + encodedPath;
    }

    /**
     * Método que se encarga de borrar la imagen del bucket de Supabase a partir de su URL pública.
     * 
     * @param publicUrl URL pública de la imagen que se desea borrar. Si es null o vacía, no se realiza ninguna acción.
     */
    public void borrarImagenEvento(@Nullable String publicUrl) {
        if (publicUrl == null || publicUrl.isBlank()) return;

        String prefix = supabaseUrl + "/storage/v1/object/public/" + bucketEventos + "/";
        if (!publicUrl.startsWith(prefix)) {
            log.warn("URL de imagen fuera del bucket: {}", publicUrl);
            return;
        }

        String objectPathEncoded = publicUrl.substring(prefix.length());

        try {
            supabaseClient.delete()
                .uri(uriBuilder -> uriBuilder
                    .path("/storage/v1/object/{bucket}/{path}")
                    .build(Map.of("bucket", bucketEventos, "path", objectPathEncoded)))
                .retrieve()
                .toBodilessEntity();
        } catch (Exception e) {
            log.warn("Error borrando imagen en Supabase Storage: {}", e.getMessage());
            throw new IllegalStateException("No se pudo borrar la imagen en el storage", e);
        }
    }

    /**
     * Método que se encarga de subir una imagen de perfil a un bucket privado.
     *
     * @param imagen Archivo de imagen.
     * @param carpeta Carpeta destino dentro del bucket.
     * @param nombreBase Nombre base para generar el nombre del fichero.
     * @return Object path privado almacenado en la BD.
     */
    public String subirImagenUsuario(MultipartFile imagen, String emailUsuario) {
        if (imagen == null || imagen.isEmpty()) {
            throw new IllegalArgumentException("Imagen vacía o nula");
        }

        byte[] bytes;
        String filename;
        String contentType;

        try {
            bytes = imagen.getBytes();
            filename = construirNombreImagenUsuario(emailUsuario, imagen.getOriginalFilename());
            contentType = imagen.getContentType();
            if (contentType == null || contentType.equals("application/octet-stream")) {
                contentType = contentTypeFromFilename(filename);
            }
        } catch (IOException e) {
            throw new IllegalStateException("Error al leer el contenido de la imagen: " + imagen.getOriginalFilename(), e);
        }

        String objectPath = filename;
        String encodedPath = UriUtils.encodePath(objectPath, StandardCharsets.UTF_8);

        supabaseClient.post()
                .uri(uriBuilder -> uriBuilder
                        .path("/storage/v1/object/{bucket}/{path}")
                        .queryParam("upsert", true)
                        .build(Map.of("bucket", bucketUsuarios, "path", encodedPath)))
                .contentType(MediaType.parseMediaType(contentType))
                .body(bytes)
                .retrieve()
                .toBodilessEntity();

        return objectPath;
    }

    /**
     * Método para borrar una imagen privada a partir del object path.
     *
     * @param objectPath Path interno del objeto.
     */
    public void borrarImagenUsuario(String objectPath) {
        if (objectPath == null || objectPath.isBlank()) return;

        String encodedPath = UriUtils.encodePath(objectPath, StandardCharsets.UTF_8);

        try {
            supabaseClient.delete()
                    .uri(uriBuilder -> uriBuilder
                            .path("/storage/v1/object/{bucket}/{path}")
                            .build(Map.of("bucket", bucketUsuarios, "path", encodedPath)))
                    .retrieve()
                    .toBodilessEntity();
        } catch (Exception e) {
            log.warn("Error borrando imagen usuario: {}", e.getMessage());
            throw new IllegalStateException("No se pudo borrar la imagen usuario", e);
        }
    }

    /**
     * Método para generar una URL firmada de un objeto privado.
     *
     * @param objectPath Path interno del objeto.
     * @param expiresSeconds Segundos de validez de la URL.
     * @return URL firmada completa.
     */
    public String generarUrlFirmada(String objectPath, int expiresSeconds) {
        if (objectPath == null || objectPath.isBlank()) {
            return null;
        }

        String encodedPath = UriUtils.encodePath(objectPath, StandardCharsets.UTF_8);

        Map<?, ?> response = supabaseClient.post()
                .uri(uriBuilder -> uriBuilder
                        .path("/storage/v1/object/sign/{bucket}/{path}")
                        .build(Map.of("bucket", bucketUsuarios, "path", encodedPath)))
                .body(Map.of("expiresIn", expiresSeconds))
                .retrieve()
                .body(Map.class);

        if (response == null || !response.containsKey("signedURL")) {
            throw new IllegalStateException("No se pudo generar URL firmada");
        }

        String signed = String.valueOf(response.get("signedURL"));

        if (signed.startsWith("http")) {
            URI uri = URI.create(signed);
            String path = uri.getPath();
            String query = uri.getQuery();
            if (path != null && path.startsWith("/object/")) {
                String fixed = supabaseUrl + "/storage/v1" + path;
                return query == null ? fixed : fixed + "?" + query;
            }
            return signed;
        }

        if (signed.startsWith("/storage/v1")) {
            return supabaseUrl + signed;
        }

        if (signed.startsWith("/object/")) {
            return supabaseUrl + "/storage/v1" + signed;
        }

        return supabaseUrl + "/storage/v1/" + signed.replaceFirst("^/", "");
    }

    /**
     * Método para obtener el nombre de la imagen desde la URL.
     *
     * @param url URL de la imagen de origen.
     * @return Nombre de la imagen.
     */
    private static String obtenerNombreImagenDesdeUrl(String url, String tituloEvento) {
        String nombreImagen;

        try {
            String path = URI.create(url).getPath();
            String last = (path == null) ? "" : path.substring(path.lastIndexOf('/') + 1);
            if (!last.isBlank() && last.contains(".")) {
                nombreImagen = last;
            } else {
                nombreImagen = url;
            }
        } catch (IllegalArgumentException e) {
            nombreImagen = url;
        }

        return construirNombreImagenEvento(tituloEvento, nombreImagen);
    }

    
    /**
     * Método para construir el nombre de la imagen del evento a partir del título del evento y el nombre original del archivo.
     * 
     * @param tituloEvento Título del evento, se usará como base para el nombre de la imagen.
     * @param nombreArchivoOriginal Nombre original del archivo para extraer la extensión y generar el nombre final.
     * @return Nombre construido para la imagen del evento, con formato "base.extensión".
     */
    private static String construirNombreImagenEvento(String tituloEvento, String nombreArchivoOriginal) {
        // Separar base + extensión.
        int indice = nombreArchivoOriginal.lastIndexOf('.');
        String extension = nombreArchivoOriginal.substring(indice).toLowerCase();

        // Reemplazar espacios por '-'
        tituloEvento = tituloEvento.replaceAll("\\s+", "-");

        // Limpia los caracteres no seguros en rutas.
        tituloEvento = tituloEvento.replaceAll("[^a-zA-Z0-9_-]", "-");

        return tituloEvento + extension;
    }

    /**
     * Método para construir el nombre de la imagen de perfil a partir del email del usuario y el nombre original del archivo.
     * 
     * @param email Email del usuario, se usará la parte antes de '@' como base del nombre.
     * @param nombreArchivoOriginal Nombre original del archivo para extraer la extensión.
     * @return Nombre construido para la imagen de perfil, con formato "base.extensión".
     */
    private static String construirNombreImagenUsuario(String email, String nombreArchivoOriginal) {
        String base = email;
        if (base != null && base.contains("@")) {
            base = base.substring(0, base.indexOf('@'));
        }

        String extension = "";
        if (nombreArchivoOriginal != null) {
            int indice = nombreArchivoOriginal.lastIndexOf('.');
            if (indice >= 0) {
                extension = nombreArchivoOriginal.substring(indice).toLowerCase();
            }
        }

        return base + extension;
    }

    /**
     * Método que en función de como termine la extensión, sacamos el tipo de imagen
     * la cual se incluye en las cabeceras a la hora de subir la imagen para indicarle a Supabase
     * el tipo de imagen.
     *
     * @param filename Imagen.
     * @return Tipo de imagen.
     */
    private static String contentTypeFromFilename(String filename) {
        String f = filename.toLowerCase();
        if (f.endsWith(".png")) return "image/png";
        if (f.endsWith(".jpg") || f.endsWith(".jpeg")) return "image/jpeg";
        return "application/octet-stream";
    }
}