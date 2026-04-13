package es.nullpointers.eventvsmerida.dto.request;

import com.fasterxml.jackson.annotation.JsonFormat;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * DTO para la creación o actualización de una relación entre un usuario y un evento.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
public record UsuarioEventoRequest(
        @NotBlank
        @Email
        String emailUsuario,

        @NotBlank
        String tituloEvento,

        @NotNull
        LocalDateTime fechaInicioEvento,

        @NotNull
        LocalDateTime fechaFinEvento
) {}