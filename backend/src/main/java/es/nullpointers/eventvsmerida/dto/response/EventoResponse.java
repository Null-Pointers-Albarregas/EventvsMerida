package es.nullpointers.eventvsmerida.dto.response;

import java.time.Instant;
import java.time.LocalDateTime;

/**
 * DTO para devolver los datos de un evento.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
public record EventoResponse(
        String titulo,
        String descripcion,
        LocalDateTime fechaInicio,
        LocalDateTime fechaFin,
        String localizacion,
        String foto,
        String emailUsuario,
        String nombreCategoria
) {}