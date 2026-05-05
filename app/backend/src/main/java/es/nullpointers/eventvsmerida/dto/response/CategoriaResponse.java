package es.nullpointers.eventvsmerida.dto.response;

/**
 * DTO para devolver los datos de una categoría.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
public record CategoriaResponse(
        Long id,
        String nombre
) {}