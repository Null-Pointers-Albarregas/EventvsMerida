package es.nullpointers.eventvsmerida.service;

import es.nullpointers.eventvsmerida.dto.request.EventoCrearRequest;
import es.nullpointers.eventvsmerida.dto.request.EventoImagenCrearRequest;
import es.nullpointers.eventvsmerida.dto.response.EventoResponse;
import es.nullpointers.eventvsmerida.dto.request.EventoActualizarRequest;
import es.nullpointers.eventvsmerida.entity.Categoria;
import es.nullpointers.eventvsmerida.entity.Evento;
import es.nullpointers.eventvsmerida.entity.Usuario;
import es.nullpointers.eventvsmerida.mapper.EventoMapper;
import es.nullpointers.eventvsmerida.repository.EventoRepository;
import es.nullpointers.eventvsmerida.supabase.SupabaseStorage;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.NoSuchElementException;
import java.util.stream.Collectors;

/**
 * Servicio para gestionar la lógica de negocio relacionada con la
 * entidad Evento.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
@Slf4j
@RequiredArgsConstructor
@Service
public class EventoService {
    private final EventoRepository eventoRepository;
    private final UsuarioService usuarioService;
    private final CategoriaService categoriaService;
    private final SupabaseStorage storageUploader;

    // ============
    // Metodos CRUD
    // ============

    /**
     * Método para obtener todos los eventos.
     *
     * @return Lista de eventos.
     */
    public List<EventoResponse> obtenerEventos() {
        List<Evento> eventos = eventoRepository.findAll();
        List<EventoResponse> eventosResponse = new ArrayList<>();

        for (Evento evento : eventos) {
            eventosResponse.add(EventoMapper.convertirAResponse(evento));
        }

        return eventosResponse;
    }

    /**
     * Método para obtener un evento por su ID.
     *
     * @param id ID del evento a obtener.
     * @return Evento encontrado.
     */
    public EventoResponse obtenerEventoPorId(Long id) {
        Evento eventoObtenido = obtenerEventoPorIdOExcepcion(id, "Error en EventoService.obtenerEventoPorId: No se encontró el evento con id " + id);
        return EventoMapper.convertirAResponse(eventoObtenido);
    }

    /**
     * Métooo para crear un nuevo evento.
     *
     * @param eventoRequest Datos del evento a crear.
     * @return Evento creado.
     */
    public EventoResponse crearEvento(EventoCrearRequest eventoRequest) {
        // Se hacen las comprobaciones necesarias para evitar errores de integridad de datos
        if (eventoRepository.existsByTituloAndFechaInicioAndFechaFin(eventoRequest.titulo(), eventoRequest.fechaInicio(), eventoRequest.fechaFin())) {
            throw new DataIntegrityViolationException("Ya existe un evento con el título y fecha indicados");
        }

        Usuario usuario = usuarioService.obtenerUsuarioPorIdOExcepcion(eventoRequest.idUsuario(), "Error en EventoService.crearEvento: No se encontró el usuario con id " + eventoRequest.idUsuario());
        Categoria categoria = categoriaService.obtenerCategoriaPorIdOExcepcion(eventoRequest.idCategoria(), "Error en EventoService.crearEvento: No se encontró la categoría con id " + eventoRequest.idCategoria());

        // Se convierte el DTO a entidad
        Evento eventoNuevo = EventoMapper.convertirAEntidad(eventoRequest, usuario, categoria, storageUploader);

        // Se guarda el nuevo evento en la base de datos
        Evento eventoCreado = eventoRepository.save(eventoNuevo);

        // Se devuelve el evento creado convertido a response
        return EventoMapper.convertirAResponse(eventoCreado);
    }

    public EventoResponse crearEventoConImagen(EventoImagenCrearRequest eventoRequest, MultipartFile imagen) {
        // Se hacen las comprobaciones necesarias para evitar errores de integridad de datos
        if (eventoRepository.existsByTituloAndFechaInicioAndFechaFin(eventoRequest.titulo(), eventoRequest.fechaInicio(), eventoRequest.fechaFin())) {
            throw new DataIntegrityViolationException("Ya existe un evento con el título y fecha indicados");
        }

        Usuario usuario = usuarioService.obtenerUsuarioPorIdOExcepcion(eventoRequest.idUsuario(), "Error en EventoService.crearEvento: No se encontró el usuario con id " + eventoRequest.idUsuario());
        Categoria categoria = categoriaService.obtenerCategoriaPorIdOExcepcion(eventoRequest.idCategoria(), "Error en EventoService.crearEvento: No se encontró la categoría con id " + eventoRequest.idCategoria());

        // Se convierte el DTO a entidad
        Evento eventoNuevo = EventoMapper.convertirAEntidadEventoImagen(eventoRequest, imagen, usuario, categoria, storageUploader);

        // Se guarda el nuevo evento en la base de datos
        Evento eventoCreado = eventoRepository.save(eventoNuevo);

        // Se devuelve el evento creado convertido a response
        return EventoMapper.convertirAResponse(eventoCreado);
    }

    /**
     * Método para eliminar un evento por su ID.
     *
     * @param id ID del evento a eliminar.
     */
    public void eliminarEvento(Long id) {
        Evento evento = obtenerEventoPorIdOExcepcion(id, "Error en EventoService.eliminarEvento: No se encontró el evento con id " + id);
        eventoRepository.delete(evento);
    }

    /**
     * Método para actualizar un evento existente.
     *
     * @param id ID del evento a actualizar.
     * @param eventoRequest Datos actualizados del evento.
     * @return Evento actualizado.
     */
    public EventoResponse actualizarEvento(Long id, EventoActualizarRequest eventoRequest) {
        Evento eventoExistente = obtenerEventoPorIdOExcepcion(id, "Error en EventoService.actualizarEvento: No se encontró el evento con id " + id);

        // Se actualizan solo los campos que no sean nulos en el request, permitiendo actualizaciones parciales
        if (eventoRequest.titulo() != null) {
            eventoExistente.setTitulo(eventoRequest.titulo());
        }

        if (eventoRequest.descripcion() != null) {
            eventoExistente.setDescripcion(eventoRequest.descripcion());
        }

        if (eventoRequest.fechaInicio() != null) {
            eventoExistente.setFechaInicio(eventoRequest.fechaInicio());
        }

        if  (eventoRequest.fechaFin() != null) {
            eventoExistente.setFechaFin(eventoRequest.fechaFin());
        }

        if (eventoRequest.localizacion() != null) {
            eventoExistente.setLocalizacion(eventoRequest.localizacion());
        }

        if (eventoRequest.latitud() != null) {
            eventoExistente.setLatitud(eventoRequest.latitud());
        }

        if (eventoRequest.longitud() != null) {
            eventoExistente.setLongitud(eventoRequest.longitud());
        }

        if (eventoRequest.foto() != null) {
            eventoExistente.setFoto(eventoRequest.foto());
        }

        if (eventoRequest.idUsuario() != null) {
            Usuario usuario = usuarioService.obtenerUsuarioPorIdOExcepcion(eventoRequest.idUsuario(), "Error en EventoService.actualizarEvento: No se encontró el usuario con id " + eventoRequest.idUsuario());
            eventoExistente.setUsuario(usuario);
        }

        if (eventoRequest.idCategoria() != null) {
            Categoria categoria = categoriaService.obtenerCategoriaPorIdOExcepcion(eventoRequest.idCategoria(), "Error en EventoService.actualizarEvento: No se encontró la categoría con id " + eventoRequest.idCategoria());
            eventoExistente.setCategoria(categoria);
        }

        // Se guarda el evento actualizado en la base de datos
        Evento eventoActualizado = eventoRepository.save(eventoExistente);

        // Se devuelve el evento actualizado convertido a response
        return EventoMapper.convertirAResponse(eventoActualizado);
    }

    // =========================
    // Metodos Lógica de Negocio
    // =========================

    public List<EventoResponse> buscarEventos(String q, int limit) {
        if (q == null || q.trim().length() < 2) {
            return Collections.emptyList();
        }
        
        Page<Evento> page = eventoRepository.searchByQuery(q, PageRequest.of(0, Math.max(1, limit)));
        return page.getContent().stream()
                .map(EventoMapper::convertirAResponse)
                .collect(Collectors.toList());
    }

    // ==================
    // Metodos Auxiliares
    // ==================

    /**
     * Método auxiliar para obtener un evento por su ID o lanzar una excepción
     * personalizada si no se encuentra.
     *
     * @param id ID del evento a obtener.
     * @param mensajeError Mensaje de error para la excepción.
     * @return Evento encontrado.
     */
    public Evento obtenerEventoPorIdOExcepcion(Long id, String mensajeError) {
        return eventoRepository.findById(id).orElseThrow(() -> new NoSuchElementException(mensajeError));
    }
}