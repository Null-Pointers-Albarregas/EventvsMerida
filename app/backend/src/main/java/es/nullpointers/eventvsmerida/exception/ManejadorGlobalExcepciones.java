package es.nullpointers.eventvsmerida.exception;

import jakarta.validation.ConstraintViolationException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.ResponseEntity;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.server.ResponseStatusException;

import java.time.format.DateTimeParseException;
import java.util.Map;
import java.util.NoSuchElementException;

/**
 * Manejador global de excepciones para la aplicación.
 * Captura excepciones específicas y generales, registrando los errores
 * y devolviendo respuestas HTTP adecuadas.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
@Slf4j
@ControllerAdvice
public class ManejadorGlobalExcepciones {

    private static final Map<String, String> ERRORES = Map.ofEntries(
            Map.entry("crearRol", "Error en RolService.crearRol: "),
            Map.entry("actualizarRol", "Error en RolService.actualizarRol: "),
            Map.entry("crearUsuario", "Error en UsuarioService.crearUsuario: "),
            Map.entry("actualizarUsuario", "Error en UsuarioService.actualizarUsuario: "),
            Map.entry("crearCategoria", "Error en CategoriaService.crearCategoria: "),
            Map.entry("actualizarCategoria", "Error en CategoriaService.actualizarCategoria: "),
            Map.entry("login", "Error en UsuarioService.login: "),
            Map.entry("guardarUsuarioEvento",  "Error en UsuarioService.guardarUsuarioEvento: "),
            Map.entry("Rol_nombre_key", "Nombre duplicado introducido"),
            Map.entry("Usuario_email_key", "Email duplicado introducido"),
            Map.entry("Usuario_telefono_key", "Teléfono duplicado introducido"),
            Map.entry("Categoria_nombre_key", "Nombre duplicado introducido")
    );

    // ========================
    // Métodos ExceptionHandler
    // ========================

    /**
     * Maneja la excepción NoSuchElementException.
     *
     * @param e La excepción capturada.
     * @return Una respuesta HTTP 404 Not Found.
     */
    @ExceptionHandler(NoSuchElementException.class)
    public ResponseEntity<ErrorResponse> manejadorNoSuchElementException(NoSuchElementException e) {
        String mensajeUsuario = limpiarMensajeTecnico(e.getMessage());
        return construirRespuesta(e.getStackTrace(), HttpStatus.NOT_FOUND, e.getMessage(), mensajeUsuario);
    }

    /**
     * Maneja la excepción MethodArgumentNotValidException.
     * Se lanza cuando la validación de los argumentos de un método falla,
     * normalmente por anotaciones de validación en los DTOs (por ejemplo @NotNull, @Email, @Pattern).
     *
     * @param e La excepción capturada.
     * @return Una respuesta HTTP 400 Bad Request.
     */
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> manejadorMethodArgumentNotValidException(MethodArgumentNotValidException e) {
        String mensajeUsuario = e.getBindingResult()
                .getFieldErrors()
                .stream()
                .map(FieldError::getDefaultMessage)
                .findFirst()
                .orElse("Datos inválidos");

        return construirRespuesta(e.getStackTrace(), HttpStatus.BAD_REQUEST, mensajeUsuario, mensajeUsuario);
    }

    /**
     * Maneja la excepción DataIntegrityViolationException.
     * Se controla cuando se intenta crear un objeto de una tabla con algún
     * dato que viola restricciones de integridad.
     *
     * @param e La excepción capturada.
     * @return Una respuesta HTTP 409 Conflict.
     */
    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<ErrorResponse> manejadorDataIntegrityViolationException(DataIntegrityViolationException e) {
        String mensajeUsuario = obtenerMensajePersonalizado(e.getMessage(), null);
        return construirRespuesta(e.getStackTrace(), HttpStatus.CONFLICT, mensajeUsuario, mensajeUsuario);
    }

    /**
     * Maneja la excepción MissingServletRequestParameterException.
     * Se lanza cuando falta un parametro obligatorio de query/path en la petición.
     *
     * @param e La excepción capturada.
     * @return Una respuesta HTTP 400 Bad Request.
     */
    @ExceptionHandler(MissingServletRequestParameterException.class)
    public ResponseEntity<ErrorResponse> manejadorMissingServletRequestParameterException(MissingServletRequestParameterException e) {
        String mensajeUsuario = "Falta el parámetro obligatorio '" + e.getParameterName() + "'";
        return construirRespuesta(e.getStackTrace(), HttpStatus.BAD_REQUEST, mensajeUsuario, mensajeUsuario);
    }

    /**
     * Maneja la excepción ConstraintViolationException.
     * Se lanza cuando fallan validaciones sobre parámetros simples (query/path params).
     *
     * @param e La excepción capturada.
     * @return Una respuesta HTTP 400 Bad Request.
     */
    @ExceptionHandler(ConstraintViolationException.class)
    public ResponseEntity<ErrorResponse> manejadorConstraintViolationException(ConstraintViolationException e) {
        String mensajeUsuario = e.getMessage();
        return construirRespuesta(e.getStackTrace(), HttpStatus.BAD_REQUEST, mensajeUsuario, mensajeUsuario);
    }

    /**
     * Maneja la excepción HttpMessageNotReadableException.
     * Se lanza cuando el cuerpo de la petición no puede deserializarse correctamente,
     * normalmente por errores de formato en los datos recibidos (por ejemplo, fechas mal formateadas).
     *
     * @param e La excepción capturada.
     * @return Una respuesta HTTP 400 Bad Request.
     */
    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<ErrorResponse> manejadorHttpMessageNotReadableException(HttpMessageNotReadableException e) {
        Throwable causa = e.getMostSpecificCause();
        String mensajeUsuario;

        if (causa instanceof DateTimeParseException) {
            String formatoEsperado = "dd/MM/yyyy";
            mensajeUsuario = "Error de formato en la fecha. Formato esperado: '" + formatoEsperado + "'. Detalle: " + causa.getMessage();
        } else {
            mensajeUsuario = "Error de formato en los datos recibidos. Detalle: " + causa.getMessage();
        }

        return construirRespuesta(e.getStackTrace(), HttpStatus.BAD_REQUEST, mensajeUsuario, mensajeUsuario);
    }

    /**
     * Maneja la excepción AuthenticationException.
     * Se lanza cuando ocurre un error de autenticación, como credenciales inválidas.
     * 
     * @param e La excepción capturada.
     * @return Una respuesta HTTP 401 Unauthorized.
     */
    @ExceptionHandler(AuthenticationException.class)
    public ResponseEntity<ErrorResponse> manejadorAuthenticationException(AuthenticationException e) {
        String mensajeUsuario = e.getMessage() != null ? e.getMessage() : "Credenciales inválidas";
        return construirRespuesta(e.getStackTrace(), HttpStatus.UNAUTHORIZED, mensajeUsuario, mensajeUsuario);
    }

    /**
     * Maneja la excepción AccessDeniedException.
     * Se lanza cuando un usuario autenticado intenta acceder a un recurso para el cual no tiene permisos.
     * 
     * @param e La excepción capturada.
     * @return Una respuesta HTTP 403 Forbidden.
     */
    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<ErrorResponse> manejadorAccessDeniedException(AccessDeniedException e) {
        String mensajeUsuario = e.getMessage() != null ? e.getMessage() : "Acceso denegado";
        return construirRespuesta(e.getStackTrace(), HttpStatus.FORBIDDEN, mensajeUsuario, mensajeUsuario);
    }

    /**
     * Maneja la excepción en caso de que se quiera insertar una imagen que ya está almacenada.
     * 
     * @param e Excepción capturada.
     * @return Respuesta HTTP con el código 409.
     */
    @ExceptionHandler(ResponseStatusException.class)
    public ResponseEntity<ErrorResponse> manejadorResponseStatus(ResponseStatusException e) {
        String mensajeUsuario = e.getReason() != null ? e.getReason() : e.getMessage();
        return construirRespuesta(e.getStackTrace(), HttpStatus.valueOf(e.getStatusCode().value()), mensajeUsuario, mensajeUsuario);
    }

    /**
     * Maneja la excepción EventoFotoImagenException.
     * Se lanza cuando hay un error de validación con la foto e imagen del evento.
     *
     * @param e La excepción capturada.
     * @return Una respuesta HTTP 400 Bad Request.
     */
    @ExceptionHandler(EventoFotoImagenException.class)
    public ResponseEntity<ErrorResponse> manejadorEventoFotoImagenException(EventoFotoImagenException e) {
        return construirRespuesta(e.getStackTrace(), HttpStatus.BAD_REQUEST, e.getMessage(), e.getMessage());
    }

    /**
     * Maneja cualquier otra excepción no específica.
     *
     * @param e La excepción capturada.
     * @return Una respuesta HTTP 500 Internal Server Error.
     */
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> manejadoreGeneralException(Exception e) {
        String mensajeUsuario = e.getMessage() != null ? e.getMessage() : "Error interno del servidor";
        return construirRespuesta(e.getStackTrace(), HttpStatus.INTERNAL_SERVER_ERROR, mensajeUsuario, mensajeUsuario);
    }

    // ================
    // Métodos Privados
    // ================

    /**
     * Método auxiliar para obtener la clase y el método
     * desde el stack trace de una excepción.
     *
     * @param stackTrace El stack trace de la excepción.
     * @return Una cadena con el formato "Clase.Método" o "desconocido" si no se encuentra.
     */
    private String obtenerClaseMetodoDesdeStackTrace(StackTraceElement[] stackTrace) {
        for (StackTraceElement ste : stackTrace) {
            String className = ste.getClassName();

            // Filtrar solo las clases del paquete de la aplicación, excluyendo excepciones y clases internas
            if (className.startsWith("es.nullpointers.eventvsmerida") && !className.contains("exception") && !className.contains("$")) {
                return className.substring(className.lastIndexOf('.') + 1) + "." + ste.getMethodName();
            }
        }

        return "desconocido";
    }

    /**
     * Método auxiliar para obtener un mensaje personalizado
     * basado en el mensaje original y un mapa de errores conocidos.
     *
     * @param mensaje El mensaje original de la excepción.
     * @param errores Detalles adicionales de errores, si los hay.
     * @return Un mensaje personalizado si se encuentra una coincidencia, o el mensaje original.
     */
    private String obtenerMensajePersonalizado(String mensaje, String errores) {
        for (Map.Entry<String, String> entry : ERRORES.entrySet()) {
            if (mensaje.contains(entry.getKey())) {
                return entry.getValue() + (errores != null ? errores : "");
            }
        }

        return mensaje;
    }

    /**
     * Método auxiliar para limpiar el mensaje técnico de una excepción,
     * extrayendo solo la parte relevante para el usuario.
     * 
     * @param mensaje El mensaje técnico original de la excepción.
     * @return Un mensaje más limpio y amigable para el usuario.
     */
    private String limpiarMensajeTecnico(String mensaje) {
        if (mensaje == null || mensaje.isBlank()) {
            return "No se encontró el recurso solicitado";
        }

        if (mensaje.contains(":")) {
            return mensaje.substring(mensaje.indexOf(":") + 1).trim();
        }

        return mensaje;
    }


    private ResponseEntity<ErrorResponse> construirRespuesta(StackTraceElement[] stackTrace, HttpStatus status, String mensajeLog, String mensajeRespuesta) {
        String claseMetodo = obtenerClaseMetodoDesdeStackTrace(stackTrace);
        log.error("Error en " + claseMetodo + ": " + mensajeLog);
        return ResponseEntity.status(status).body(new ErrorResponse(mensajeRespuesta));
    }
}