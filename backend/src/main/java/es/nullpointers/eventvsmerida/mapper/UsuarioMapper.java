package es.nullpointers.eventvsmerida.mapper;

import es.nullpointers.eventvsmerida.dto.request.UsuarioCrearRequest;
import es.nullpointers.eventvsmerida.dto.response.UsuarioResponse;
import es.nullpointers.eventvsmerida.entity.Rol;
import es.nullpointers.eventvsmerida.entity.Usuario;
import es.nullpointers.eventvsmerida.utils.TextoUtils;

import java.time.LocalDate;

/**
 * Clase mapper que convierte entre objetos DTO y entidades
 * relacionadas con la entidad Usuario.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
public class UsuarioMapper {

    /**
     * Metodo que convierte un objeto UsuarioCrearRequest a una entidad Usuario,
     * capitalizando y normalizando los campos de texto.
     *
     * @param request Objeto DTO con los datos del usuario.
     * @param rol Rol asignado al usuario.
     * @return Entidad Usuario creada a partir del DTO.
     */
    public static Usuario convertirAEntidad(UsuarioCrearRequest request, Rol rol) {
        Usuario usuario = new Usuario();

        usuario.setNombre(TextoUtils.capitalizarTexto(request.nombre()));
        usuario.setApellidos(TextoUtils.capitalizarTexto(request.apellidos()));
        usuario.setFechaNacimiento(request.fechaNacimiento());
        usuario.setEmail(TextoUtils.normalizarTexto(request.email()));
        usuario.setTelefono(request.telefono());
        usuario.setPassword(request.password());
        usuario.setRol(rol);

        return usuario;
    }

    /**
     * Metodo que convierte una entidad Usuario a un objeto UsuarioResponse.
     *
     * @param usuario Entidad Usuario a convertir.
     * @return Objeto DTO con los datos del usuario.
     */
    public static UsuarioResponse convertirAResponse(Usuario usuario) {
        Long id = usuario.getId();
        String nombre = usuario.getNombre();
        String apellidos = usuario.getApellidos();
        LocalDate fechaNacimiento = usuario.getFechaNacimiento();
        String email = usuario.getEmail();
        String telefono = usuario.getTelefono();
        String rol = usuario.getRol().getNombre();

        return new UsuarioResponse(id, nombre, apellidos, fechaNacimiento, email, telefono, rol);
    }
}