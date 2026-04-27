package es.nullpointers.eventvsmerida.mapper;

import es.nullpointers.eventvsmerida.dto.request.CategoriaRequest;
import es.nullpointers.eventvsmerida.dto.response.CategoriaResponse;
import es.nullpointers.eventvsmerida.entity.Categoria;
import es.nullpointers.eventvsmerida.utils.TextoUtils;

/**
 * Clase mapper que convierte entre objetos DTO y entidades
 * relacionadas con la entidad Categoría.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
public class CategoriaMapper {

    /**
     * Metodo que convierte un objeto CategoriaRequest a una entidad Categoria,
     * capitalizando el nombre de la categoría.
     *
     * @param request Objeto DTO con los datos de la categoría.
     * @return Entidad Categoria creada a partir del DTO.
     */
    public static Categoria convertirAEntidad(CategoriaRequest request) {
        Categoria categoria = new Categoria();
        categoria.setNombre(TextoUtils.capitalizarTexto(request.nombre()));
        
        return categoria;
    }

    /**
     * Metodo que convierte una entidad Categoria a un objeto CategoriaResponse.
     *
     * @param categoria Entidad Categoria a convertir.
     * @return Objeto DTO con los datos de la categoría.
     */
    public static CategoriaResponse convertirAResponse(Categoria categoria) {
        String nombre = categoria.getNombre();
        Long id = categoria.getId();

        return new CategoriaResponse(id, nombre);
    }
}