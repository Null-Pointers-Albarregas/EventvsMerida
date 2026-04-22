package es.nullpointers.eventvsmerida.dto.request;

import java.time.LocalDateTime;

/**
 * DTO para la actualización de un evento.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
public record EventoActualizarRequest(
        String titulo,
        String descripcion,
        LocalDateTime fechaInicio,
        LocalDateTime fechaFin,
        String localizacion,
        Double latitud,
        Double longitud,
        String foto,
        Long idUsuario,
        Long idCategoria
) {}