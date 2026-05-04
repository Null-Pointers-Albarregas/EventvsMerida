package es.nullpointers.eventvsmerida.mapper;

import es.nullpointers.eventvsmerida.dto.request.UsuarioCrearRequest;
import es.nullpointers.eventvsmerida.dto.response.UsuarioResponse;
import es.nullpointers.eventvsmerida.entity.Rol;
import es.nullpointers.eventvsmerida.entity.Usuario;
import es.nullpointers.eventvsmerida.supabase.SupabaseStorage;
import es.nullpointers.eventvsmerida.utils.TextoUtils;
import org.springframework.web.multipart.MultipartFile;

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
     * @param imagen Imagen de perfil (opcional).
     * @param storage Servicio para subir imagen privada.
     * @return Entidad Usuario creada a partir del DTO.
     */
    public static Usuario convertirAEntidad(UsuarioCrearRequest request, Rol rol, MultipartFile imagen, SupabaseStorage storage) {
        Usuario usuario = new Usuario();

        usuario.setNombre(TextoUtils.capitalizarTexto(request.nombre()));
        usuario.setApellidos(TextoUtils.capitalizarTexto(request.apellidos()));
        usuario.setFechaNacimiento(request.fechaNacimiento());
        usuario.setEmail(TextoUtils.normalizarTexto(request.email()));
        usuario.setTelefono(request.telefono());
        usuario.setPassword(request.password());
        usuario.setRol(rol);

        String objectPath = null;
        if (imagen != null && !imagen.isEmpty()) {
            objectPath = storage.subirImagenPrivada(imagen, "usuarios", request.nombre());
        } else if (request.fotoPath() != null && !request.fotoPath().isBlank()) {
            objectPath = request.fotoPath();
        }

        usuario.setFotoPath(objectPath);
        return usuario;
    }

    /**
     * Metodo que convierte una entidad Usuario a un objeto UsuarioResponse.
     *
     * @param usuario Entidad Usuario a convertir.
     * @param storage Servicio para generar URL firmada.
     * @return Objeto DTO con los datos del usuario.
     */
    public static UsuarioResponse convertirAResponse(Usuario usuario, SupabaseStorage storage) {
        Long id = usuario.getId();
        String nombre = usuario.getNombre();
        String apellidos = usuario.getApellidos();
        LocalDate fechaNacimiento = usuario.getFechaNacimiento();
        String email = usuario.getEmail();
        String telefono = usuario.getTelefono();
        String rol = usuario.getRol().getNombre();

        String fotoUrl = null;
        if (usuario.getFotoPath() != null && !usuario.getFotoPath().isBlank()) {
            fotoUrl = storage.generarUrlFirmada(usuario.getFotoPath(), 3600);
        }

        return new UsuarioResponse(id, nombre, apellidos, fechaNacimiento, email, telefono, rol, fotoUrl);
    }
}