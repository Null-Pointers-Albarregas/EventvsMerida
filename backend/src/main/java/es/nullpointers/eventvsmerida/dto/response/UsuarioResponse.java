package es.nullpointers.eventvsmerida.dto.response;

import java.time.LocalDate;

/**
 * DTO para devolver los datos de un usuario.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
public record UsuarioResponse (
        Long id,
        String nombre,
        String apellidos,
        LocalDate fechaNacimiento,
        String email,
        String telefono,
        String rol
){}