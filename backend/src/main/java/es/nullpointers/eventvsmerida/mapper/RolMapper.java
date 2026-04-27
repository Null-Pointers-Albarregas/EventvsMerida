package es.nullpointers.eventvsmerida.mapper;

import es.nullpointers.eventvsmerida.dto.request.RolRequest;
import es.nullpointers.eventvsmerida.dto.response.RolResponse;
import es.nullpointers.eventvsmerida.entity.Rol;
import es.nullpointers.eventvsmerida.utils.TextoUtils;

/**
 * Clase mapper que convierte entre objetos DTO y entidades
 * relacionadas con la entidad Rol.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
public class RolMapper {

    /**
     * Metodo que convierte un objeto RolRequest a una entidad Rol,
     * capitalizando el nombre del rol.
     *
     * @param request Objeto DTO con los datos del rol.
     * @return Entidad Rol creada a partir del DTO.
     */
    public static Rol convertirAEntidad(RolRequest request) {
        Rol rol = new Rol();
        rol.setNombre(TextoUtils.capitalizarTexto(request.nombre()));
        return rol;
    }

    /**
     * Metodo que convierte una entidad Rol a un objeto RolResponse.
     *
     * @param rol Entidad Rol a convertir.
     * @return Objeto DTO con los datos del rol.
     */
    public static RolResponse convertirAResponse(Rol rol) {
        String nombre = rol.getNombre();
        Long id = rol.getId();

        return new RolResponse(id, nombre);
    }
}