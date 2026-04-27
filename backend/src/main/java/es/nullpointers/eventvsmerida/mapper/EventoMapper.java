package es.nullpointers.eventvsmerida.mapper;

import es.nullpointers.eventvsmerida.dto.request.EventoCrearRequest;
import es.nullpointers.eventvsmerida.dto.request.EventoImagenCrearRequest;
import es.nullpointers.eventvsmerida.dto.response.EventoResponse;
import es.nullpointers.eventvsmerida.entity.Categoria;
import es.nullpointers.eventvsmerida.entity.Evento;
import es.nullpointers.eventvsmerida.entity.Usuario;
import es.nullpointers.eventvsmerida.supabase.SupabaseStorage;
import org.springframework.web.multipart.MultipartFile;

import java.time.LocalDateTime;

/**
 * Clase mapper que convierte entre objetos DTO y entidades
 * relacionadas con la entidad Evento.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
public class EventoMapper {

    /**
     * Metodo que convierte un objeto EventoCrearRequest a una entidad Evento.
     *
     * @param request Objeto DTO con los datos del evento a crear.
     * @param usuario Usuario organizador del evento.
     * @param categoria Categoria del evento.
     * @param storageUploader Para subir la imagen al bucket de Supabase
     * @return Entidad Evento creada a partir del DTO y las entidades relacionadas.
     */
    public static Evento convertirAEntidad(EventoCrearRequest request, Usuario usuario, Categoria categoria, SupabaseStorage storageUploader) {
        Evento evento = new Evento();

        evento.setTitulo(request.titulo());
        evento.setDescripcion(request.descripcion());
        evento.setFechaInicio(request.fechaInicio());
        evento.setFechaFin(request.fechaFin());
        evento.setLocalizacion(request.localizacion());
        evento.setLatitud(request.latitud());
        evento.setLongitud(request.longitud());
        evento.setFoto(storageUploader.subirImagen(request.foto(), null, evento.getTitulo()));
        evento.setUsuario(usuario);
        evento.setCategoria(categoria);

        return evento;
    }

    /**
     * Metodo que convierte un objeto EventoImagenCrearRequest a una entidad Evento, subiendo la imagen al bucket de Supabase.
     * Se utiliza para crear un evento con una imagen subida por el usuario.
     * 
     * @param request Objeto DTO con los datos del evento a crear, sin la URL de la imagen.
     * @param imagen Archivo de imagen subido por el usuario para el evento.
     * @param usuario Usuario organizador del evento.
     * @param categoria Categoria del evento.
     * @param storageUploader Para subir la imagen al bucket de Supabase y obtener la URL de la imagen subida.
     * @return Entidad Evento creada a partir del DTO, la imagen subida y las entidades relacionadas.
     */
    public static Evento convertirAEntidadEventoImagen(EventoImagenCrearRequest request, MultipartFile imagen, Usuario usuario, Categoria categoria, SupabaseStorage storageUploader) {
        Evento evento = new Evento();

        evento.setTitulo(request.titulo());
        evento.setDescripcion(request.descripcion());
        evento.setFechaInicio(request.fechaInicio());
        evento.setFechaFin(request.fechaFin());
        evento.setLocalizacion(request.localizacion());
        evento.setLatitud(request.latitud());
        evento.setLongitud(request.longitud());
        evento.setFoto(storageUploader.subirImagen(null, imagen, request.titulo()));
        evento.setUsuario(usuario);
        evento.setCategoria(categoria);

        return evento;
    }

    /**
     * Metodo que convierte una entidad Evento a un objeto EventoResponse.
     *
     * @param evento Entidad Evento a convertir.
     * @return Objeto DTO con los datos del evento.
     */
    public static EventoResponse convertirAResponse(Evento evento) {
        Long id = evento.getId();
        String titulo = evento.getTitulo();
        String descripcion = evento.getDescripcion();
        LocalDateTime fechaInicio = evento.getFechaInicio();
        LocalDateTime fechaFin = evento.getFechaFin();
        String localizacion = evento.getLocalizacion();
        Double latitud = evento.getLatitud();
        Double longitud = evento.getLongitud();
        String urlFoto = evento.getFoto();
        String emailOrganizador = evento.getUsuario().getEmail();
        String categoria = evento.getCategoria().getNombre();

        return new EventoResponse(id, titulo, descripcion, fechaInicio, fechaFin, localizacion, latitud, longitud, urlFoto, emailOrganizador, categoria);
    }
}