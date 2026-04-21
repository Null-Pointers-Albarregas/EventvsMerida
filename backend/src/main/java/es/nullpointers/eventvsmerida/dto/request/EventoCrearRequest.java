package es.nullpointers.eventvsmerida.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import org.springframework.web.multipart.MultipartFile;

import java.sql.Timestamp;
import java.time.LocalDateTime;

/**
 * DTO para la creación o actualización de un evento.
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
        //MultipartFile ficheroImagen,

        @NotNull
        long idUsuario,

        @NotNull
        long idCategoria
) {}