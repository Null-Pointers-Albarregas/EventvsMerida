package es.nullpointers.eventvsmerida.dto.request;

import jakarta.validation.constraints.NotBlank;

/**
 * DTO para la creación o actualización de un rol.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
public record RolRequest(
        @NotBlank
        String nombre
) {}