package es.nullpointers.eventvsmerida.dto.response;

/**
 * DTO para devolver los datos de un rol.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
public record RolResponse(
        Long id,
        String nombre
) {}