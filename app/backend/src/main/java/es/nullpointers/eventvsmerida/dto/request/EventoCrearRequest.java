package es.nullpointers.eventvsmerida.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.time.LocalDateTime;

/**
 * DTO para la creación de un evento.
 * La imagen puede ser proporcionada como URL (foto) o como archivo (en multipart).
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
public record EventoCrearRequest(
        @NotBlank
        String titulo,

        @NotBlank
        String descripcion,

        @NotNull
        LocalDateTime fechaInicio,

        @NotNull
        LocalDateTime fechaFin,

        @NotBlank
        String localizacion,

        Double latitud,
        Double longitud,

        String foto,

        @NotNull
        long idUsuario,

        @NotNull
        long idCategoria
) {}