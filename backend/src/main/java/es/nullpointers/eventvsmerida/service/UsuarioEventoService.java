package es.nullpointers.eventvsmerida.service;

import es.nullpointers.eventvsmerida.dto.request.UsuarioEventoRequest;
import es.nullpointers.eventvsmerida.dto.response.EventoResponse;
import es.nullpointers.eventvsmerida.entity.Usuario;
import es.nullpointers.eventvsmerida.entity.Evento;
import es.nullpointers.eventvsmerida.entity.UsuarioEvento;
import es.nullpointers.eventvsmerida.entity.UsuarioEventoId;
import es.nullpointers.eventvsmerida.mapper.EventoMapper;
import es.nullpointers.eventvsmerida.repository.UsuarioRepository;
import es.nullpointers.eventvsmerida.repository.EventoRepository;
import es.nullpointers.eventvsmerida.repository.UsuarioEventoRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.ZoneId;
import java.util.List;
import java.util.NoSuchElementException;

/**
 * Servicio para gestionar la logica de negocio relacionada con la
 * entidad UsuarioEvento.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class UsuarioEventoService {
    private final UsuarioRepository usuarioRepository;
    private final EventoRepository eventoRepository;
    private final UsuarioEventoRepository usuarioEventoRepository;

    public void guardarUsuarioEvento(UsuarioEventoRequest request) {
        // Buscar el usuario por email y el evento por título y fechaHora, lanzando excepciones si no se encuentran
        Usuario usuario = usuarioRepository.findByEmail(request.emailUsuario())
                .orElseThrow(() -> new NoSuchElementException("Error en UsuarioEventoService.guardarUsuarioEvento: No se encontró el usuario con email " + request.emailUsuario()));

        Evento evento = eventoRepository.findByTituloAndFechaInicioAndFechaFin(request.tituloEvento(), request.fechaInicioEvento(), request.fechaFinEvento())
                .orElseThrow(() -> new NoSuchElementException("Error en UsuarioEventoService.guardarUsuarioEvento: No se encontró el evento con título '" + request.tituloEvento()
                        + "' y fechaInicio " + request.fechaInicioEvento() + " y fechaFin " + request.fechaFinEvento()));

        // Verificar si la relación ya existe antes de guardarla, lanzando una excepción si es así
        UsuarioEventoId id = new UsuarioEventoId();
        id.setIdUsuario(usuario.getId());
        id.setIdEvento(evento.getId());

        if (usuarioEventoRepository.existsById(id)) {
            throw new IllegalStateException("Error en UsuarioEventoService.guardarUsuarioEvento: El usuario ya tiene guardado este evento");
        }

        // Crear la relación entre el usuario y el evento y guardarla en la base de datos
        UsuarioEvento relacion = new UsuarioEvento();
        relacion.setId(id);
        relacion.setUsuario(usuario);
        relacion.setEvento(evento);

        usuarioEventoRepository.save(relacion);
    }

    public void eliminarUsuarioEvento(UsuarioEventoRequest request) {
        // Buscar el usuario por email y el evento por título y fechaHora, lanzando excepciones si no se encuentran
        Usuario usuario = usuarioRepository.findByEmail(request.emailUsuario())
                .orElseThrow(() -> new NoSuchElementException("Error en UsuarioEventoService.eliminarUsuarioEvento: No se encontró el usuario con email " + request.emailUsuario()));

        Evento evento = eventoRepository.findByTituloAndFechaInicioAndFechaFin(request.tituloEvento(), request.fechaInicioEvento(),  request.fechaFinEvento())
                .orElseThrow(() -> new NoSuchElementException("Error en UsuarioEventoService.eliminarUsuarioEvento: No se encontró el evento con título '" + request.tituloEvento()
                        + "' y fechaInicio " + request.fechaInicioEvento() + " y fechaFin " + request.fechaFinEvento()));

        // Verificar si la relación existe antes de eliminarla, lanzando una excepción si no es así
        UsuarioEventoId id = new UsuarioEventoId();
        id.setIdUsuario(usuario.getId());
        id.setIdEvento(evento.getId());

        if (!usuarioEventoRepository.existsById(id)) {
            throw new NoSuchElementException("Error en UsuarioEventoService.eliminarUsuarioEvento: El usuario no tenía guardado este evento");
        }

        // Eliminar la relación entre el usuario y el evento de la base de datos
        usuarioEventoRepository.deleteById(id);
    }

    public List<EventoResponse> obtenerEventosGuardadosPorUsuario(String emailUsuario) {
        // Buscar el usuario por email, lanzando una excepción si no se encuentra
        Usuario usuario = usuarioRepository.findByEmail(emailUsuario)
                .orElseThrow(() -> new NoSuchElementException("Error en UsuarioEventoService.obtenerEventosGuardadosPorUsuario: No se encontró el usuario con email " + emailUsuario));

        // Buscar las relaciones entre el usuario y los eventos guardados, lanzando una excepción si no se encuentran
        List<UsuarioEvento> relaciones = usuarioEventoRepository.findByIdIdUsuario(usuario.getId());
        if (relaciones.isEmpty()) {
            throw new NoSuchElementException("Error en UsuarioEventoService.obtenerEventosGuardadosPorUsuario: El usuario con email " + emailUsuario + " no tiene eventos guardados");
        }

        // Convertir las entidades Evento a DTOs EventoResponse y devolver la lista resultante
        return relaciones.stream()
                .map(relacion -> EventoMapper.convertirAResponse(relacion.getEvento()))
                .toList();
    }
}