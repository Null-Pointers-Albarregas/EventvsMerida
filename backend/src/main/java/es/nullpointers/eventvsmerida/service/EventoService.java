package es.nullpointers.eventvsmerida.service;

import es.nullpointers.eventvsmerida.dto.request.EventoCrearRequest;
import es.nullpointers.eventvsmerida.dto.response.EventoResponse;
import es.nullpointers.eventvsmerida.dto.request.EventoActualizarRequest;
import es.nullpointers.eventvsmerida.entity.Categoria;
import es.nullpointers.eventvsmerida.entity.Evento;
import es.nullpointers.eventvsmerida.entity.Usuario;
import es.nullpointers.eventvsmerida.exception.EventoFotoImagenException;
import es.nullpointers.eventvsmerida.mapper.EventoMapper;
import es.nullpointers.eventvsmerida.repository.EventoRepository;
import es.nullpointers.eventvsmerida.supabase.SupabaseStorage;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;
import org.springframework.web.multipart.MultipartFile;

import java.time.LocalDateTime;
import java.time.OffsetDateTime;
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
     * Método para crear un nuevo evento.
     * Soporta tanto URL de imagen como archivo subido por el usuario.
     *
     * @param eventoRequest Datos del evento a crear.
     * @param imagen MultipartFile opcional de la imagen (si es null, usa la URL del request).
     * @return Evento creado.
     */
    public EventoResponse crearEvento(EventoCrearRequest eventoRequest, MultipartFile imagen) {
        // Validar que se proporcione foto o imagen, pero no ambas
        boolean tieneUrl = eventoRequest.foto() != null && !eventoRequest.foto().isBlank();
        boolean tieneArchivo = imagen != null && !imagen.isEmpty();
        
        if (!tieneUrl && !tieneArchivo) {
            throw new EventoFotoImagenException(
                "Debes proporcionar una imagen: 'foto' (URL) o 'imagen' (archivo)");
        }
        
        if (tieneUrl && tieneArchivo) {
            throw new EventoFotoImagenException(
                "No puedes enviar tanto 'foto' como 'imagen' al mismo tiempo");
        }
        
        if (eventoRepository.existsByTituloAndFechaInicioAndFechaFin(eventoRequest.titulo(), eventoRequest.fechaInicio(), eventoRequest.fechaFin())) {
            throw new DataIntegrityViolationException("Ya existe un evento con el título y fecha indicados");
        }

        Usuario usuario = usuarioService.obtenerUsuarioPorIdOExcepcion(eventoRequest.idUsuario(), "Error en EventoService.crearEvento: No se encontró el usuario con id " + eventoRequest.idUsuario());
        Categoria categoria = categoriaService.obtenerCategoriaPorIdOExcepcion(eventoRequest.idCategoria(), "Error en EventoService.crearEvento: No se encontró la categoría con id " + eventoRequest.idCategoria());

        Evento eventoNuevo = EventoMapper.convertirAEntidad(eventoRequest, imagen, usuario, categoria, storageUploader);
        Evento eventoCreado = eventoRepository.save(eventoNuevo);

        return EventoMapper.convertirAResponse(eventoCreado);
    }

    /**
     * Método para eliminar un evento por su ID y borrar su imagen asociada en el storage.
     *
     * @param id ID del evento a eliminar.
     */
    @Transactional
    public void eliminarEvento(Long id) {
        Evento evento = obtenerEventoPorIdOExcepcion(id, "Error en EventoService.eliminarEvento: No se encontró el evento con id " + id);
        String foto = evento.getFoto();

        eventoRepository.delete(evento);

        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                try {
                    storageUploader.borrarImagenPorUrl(foto);
                } catch (Exception ex) {
                    log.warn("No se pudo borrar la imagen tras commit: {}", ex.getMessage());
                }
            }
        });
    }

    /**
     * Método para actualizar un evento existente por su ID, con la posibilidad de actualizar la imagen asociada.
     * 
     * @param id ID del evento a actualizar.
     * @param eventoRequest DTO con los datos del evento a actualizar, incluyendo la URL de la foto (si se quiere actualizar).
     * @param imagen Archivo de imagen opcional para actualizar la imagen del evento.
     * @return ResponseEntity con el evento actualizado y el estado HTTP 200 (OK).
     */
    @Transactional
    public EventoResponse actualizarEvento(Long id, EventoActualizarRequest eventoRequest, MultipartFile imagen) {
        Evento eventoExistente = obtenerEventoPorIdOExcepcion(id, "Error en EventoService.actualizarEvento: No se encontró el evento con id " + id);

        boolean tieneUrl = eventoRequest.foto() != null && !eventoRequest.foto().isBlank();
        boolean tieneArchivo = imagen != null && !imagen.isEmpty();

        if (tieneUrl && tieneArchivo) {
            throw new EventoFotoImagenException("No puedes enviar tanto 'foto' (URL) como 'imagen' (archivo) al mismo tiempo");
        }

        // Guardar foto anterior por si hay que borrarla tras commit
        String fotoAnterior = eventoExistente.getFoto();

        // Campos habituales
        if (eventoRequest.titulo() != null) eventoExistente.setTitulo(eventoRequest.titulo());
        if (eventoRequest.descripcion() != null) eventoExistente.setDescripcion(eventoRequest.descripcion());
        if (eventoRequest.fechaInicio() != null) eventoExistente.setFechaInicio(eventoRequest.fechaInicio());
        if (eventoRequest.fechaFin() != null) eventoExistente.setFechaFin(eventoRequest.fechaFin());
        if (eventoRequest.localizacion() != null) eventoExistente.setLocalizacion(eventoRequest.localizacion());
        if (eventoRequest.latitud() != null) eventoExistente.setLatitud(eventoRequest.latitud());
        if (eventoRequest.longitud() != null) eventoExistente.setLongitud(eventoRequest.longitud());

        if (eventoRequest.idUsuario() != null) {
            Usuario usuario = usuarioService.obtenerUsuarioPorIdOExcepcion(eventoRequest.idUsuario(), "Error en EventoService.actualizarEvento: No se encontró el usuario con id " + eventoRequest.idUsuario());
            eventoExistente.setUsuario(usuario);
        }

        if (eventoRequest.idCategoria() != null) {
            Categoria categoria = categoriaService.obtenerCategoriaPorIdOExcepcion(eventoRequest.idCategoria(), "Error en EventoService.actualizarEvento: No se encontró la categoría con id " + eventoRequest.idCategoria());
            eventoExistente.setCategoria(categoria);
        }

        // Manejo de imagen
        if (tieneArchivo) {
            if (fotoAnterior != null && !fotoAnterior.isBlank()) {
                try {
                    storageUploader.borrarImagenPorUrl(fotoAnterior);
                } catch (Exception ex) {
                    log.warn("No se pudo borrar la imagen anterior: {}", ex.getMessage());
                }
            }

            String nombreParaSubir = eventoRequest.titulo() != null ? eventoRequest.titulo() : eventoExistente.getTitulo();
            String nuevaUrl = storageUploader.subirImagen(null, imagen, nombreParaSubir);
            eventoExistente.setFoto(nuevaUrl);
        } else if (tieneUrl) {
            eventoExistente.setFoto(eventoRequest.foto());
        }

        Evento eventoActualizado = eventoRepository.save(eventoExistente);
        return EventoMapper.convertirAResponse(eventoActualizado);
    }

    // =========================
    // Metodos Lógica de Negocio
    // =========================

    /**
     * Método para obtener eventos paginados.
     * 
     * @param pageable Objeto Pageable que contiene la información de paginación y ordenación de los eventos a obtener. Se puede configurar con parámetros como page, size, sort, etc.
     * @return Page<EventoResponse> con la página de eventos y el estado HTTP 200 (OK).
     */
    public Page<EventoResponse> obtenerEventosPaginados(Pageable pageable, OffsetDateTime fechaFinDesde) {
        Page<Evento> page;
        
        if (fechaFinDesde != null) {
            LocalDateTime filtro = fechaFinDesde.toLocalDateTime();
            page = eventoRepository.findByFechaFinAfter(filtro, pageable);
        } else {
            page = eventoRepository.findAll(pageable);
        }
        
        return page.map(EventoMapper::convertirAResponse);
    }

    /**
     * Método para buscar eventos por una consulta de texto que puede coincidir con el título, localización o categoría del evento.
     * La búsqueda es insensible a mayúsculas y acentos, y se requiere un mínimo de 2 caracteres para realizar la búsqueda.
     * 
     * @param q Consulta de texto para buscar eventos.
     * @param limit Número máximo de resultados a devolver.
     * @return Lista de eventos que coinciden con la consulta, convertidos a response. Si la consulta es nula o tiene menos de 2 caracteres, se devuelve una lista vacía.
     */
    public List<EventoResponse> buscarEventos(String q, int limit) {
        if (q == null || q.trim().length() < 2) {
            return Collections.emptyList();
        }
        
        Page<Evento> page = eventoRepository.searchByQuery(q, PageRequest.of(0, Math.max(1, limit)));

        return page.getContent().stream()
                .map(EventoMapper::convertirAResponse)
                .collect(Collectors.toList());
    }

    /**
     * Método para obtener eventos que pertenecen a una o varias categorías específicas.
     * 
     * @param categoriaIds Lista de IDs de categorías para filtrar los eventos. Si la lista es nula o vacía, se devuelve una lista vacía.
     * @return Lista de eventos que pertenecen a las categorías especificadas, convertidos a response. Si no se encuentran eventos para las categorías dadas, se devuelve una lista vacía.
     */
    public List<EventoResponse> obtenerEventosPorCategorias(List<Long> categoriaIds) {
        if (categoriaIds == null || categoriaIds.isEmpty()) {
            return Collections.emptyList();
        }

        List<Evento> eventos = eventoRepository.findByCategoria_IdIn(categoriaIds);

        if (eventos == null || eventos.isEmpty()) {
            return Collections.emptyList();
        }

        return eventos.stream()
                .map(EventoMapper::convertirAResponse)
                .collect(Collectors.toList());
    }

    /**
     * Método para contar el número total de eventos.
     * 
     * @return Número total de eventos.
     */
    public long contarEventos() {
        return eventoRepository.count();
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
