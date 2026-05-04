package es.nullpointers.eventvsmerida.controller;

import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import es.nullpointers.eventvsmerida.dto.request.EventoCrearRequest;
import es.nullpointers.eventvsmerida.dto.response.EventoResponse;
import es.nullpointers.eventvsmerida.dto.request.EventoActualizarRequest;
import es.nullpointers.eventvsmerida.service.EventoService;
import jakarta.validation.ConstraintViolation;
import jakarta.validation.ConstraintViolationException;
import jakarta.validation.Validator;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.core.JsonProcessingException;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.Set;

/**
 * Controlador REST que recibe las peticiones HTTP relacionadas con la
 * entidad Evento y las delega al servicio correspondiente.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
@Slf4j
@RestController
@RequiredArgsConstructor
@RequestMapping("/api/eventos")
public class EventoController {
    private final EventoService eventoService;
    private final Validator validator;

    // ============
    // Metodos CRUD
    // ============

    /**
     * Método GET que llama a EventoService para obtener todos los eventos.
     *
     * @return ResponseEntity con la lista de eventos y el estado HTTP 200 (OK).
     */
    @GetMapping("/all")
    public ResponseEntity<List<EventoResponse>> obtenerEventos() {
        List<EventoResponse> eventos = eventoService.obtenerEventos();
        return ResponseEntity.ok(eventos);
    }

    /**
     * Método GET que llama al servicio para obtener un evento por su ID.
     *
     * @param id ID del evento a obtener.
     * @return ResponseEntity con el evento encontrado y el estado HTTP 200 (OK).
     */
    @GetMapping("/{id}")
    public ResponseEntity<EventoResponse> obtenerEventoPorId(@PathVariable Long id) {
        EventoResponse eventoObtenido = eventoService.obtenerEventoPorId(id);
        return ResponseEntity.ok(eventoObtenido);
    }

    /**
     * Método POST que llama al servicio para crear un nuevo evento.
     * 
     * @param jsonEvento JSON con los datos del evento a crear, enviado como parte de un multipart/form-data.
     * @param imagen Archivo de imagen opcional para el evento, enviado como parte de un multipart/form-data.
     * @return ResponseEntity con el evento creado y el estado HTTP 201 (Created).
     */
    @PostMapping(value = "/add", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<EventoResponse> crearEvento(@RequestPart("evento") String jsonEvento, @RequestPart(value = "imagen", required = false) MultipartFile imagen) {
        ObjectMapper mapper = new ObjectMapper();
        mapper.registerModule(new JavaTimeModule());

        EventoCrearRequest eventoRequest;
        try {
            eventoRequest = mapper.readValue(jsonEvento, EventoCrearRequest.class);
        } catch (JsonProcessingException e) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "El campo 'evento' debe ser un JSON válido");
        }

        Set<ConstraintViolation<EventoCrearRequest>> violaciones = validator.validate(eventoRequest);
        if (!violaciones.isEmpty()) {
            throw new ConstraintViolationException(violaciones);
        }

        EventoResponse eventoNuevo = eventoService.crearEvento(eventoRequest, imagen);
        return ResponseEntity.status(HttpStatus.CREATED).body(eventoNuevo);
    }

    /**
     * Método DELETE que llama al servicio para eliminar un evento por su ID y borrar su imagen asociada en el storage.
     *
     * @param id ID del evento a eliminar.
     * @return ResponseEntity con el estado HTTP 204 (No Content).
     */
    @DeleteMapping("/delete/{id}")
    public ResponseEntity<Void> eliminarEvento(@PathVariable Long id) {
        eventoService.eliminarEvento(id);
        return ResponseEntity.noContent().build();
    }

    /**
     * Método PUT que llama al servicio para actualizar un evento existente por su ID, con la posibilidad de actualizar la imagen asociada.
     * 
     * @param id ID del evento a actualizar.
     * @param jsonEvento JSON con los datos del evento a actualizar, enviado como parte de un multipart/form-data.
     * @param imagen Archivo de imagen opcional para actualizar la imagen del evento, enviado como parte de un multipart/form-data.
     * @return ResponseEntity con el evento actualizado y el estado HTTP 200 (OK).
     * @throws JsonProcessingException
     */
    @PutMapping(value = "/update/{id}", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<EventoResponse> actualizarEvento(@PathVariable Long id, @RequestPart("evento") String jsonEvento, @RequestPart(value = "imagen", required = false) MultipartFile imagen) throws JsonProcessingException {

        ObjectMapper mapper = new ObjectMapper();
        mapper.registerModule(new JavaTimeModule());

        EventoActualizarRequest eventoRequest;
        try {
            eventoRequest = mapper.readValue(jsonEvento, EventoActualizarRequest.class);
        } catch (JsonProcessingException e) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "El campo 'evento' debe ser un JSON válido");
        }

        Set<ConstraintViolation<EventoActualizarRequest>> violaciones = validator.validate(eventoRequest);
        if (!violaciones.isEmpty()) {
            throw new ConstraintViolationException(violaciones);
        }

        EventoResponse eventoActualizado = eventoService.actualizarEvento(id, eventoRequest, imagen);
        return ResponseEntity.ok(eventoActualizado);
    }

    // =========================
    // Metodos Lógica de Negocio
    // =========================

    /**
     * Método GET que llama al servicio para obtener eventos paginados.
     * 
     * @param pageable Objeto Pageable que contiene la información de paginación y ordenación de los eventos a obtener. Se puede configurar con parámetros como page, size, sort, etc.
     * @return ResponseEntity con la página de eventos y el estado HTTP 200 (OK).
     */
    @GetMapping("/paginated")
    public ResponseEntity<Page<EventoResponse>> obtenerEventosPaginados(
        @PageableDefault(page = 0, size = 20, sort = "fechaInicio", direction = Sort.Direction.ASC) Pageable pageable,
        @RequestParam(name = "fechaFinDesde", required = false)
        @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime fechaFinDesde) {
    
        Page<EventoResponse> pagina = eventoService.obtenerEventosPaginados(pageable, fechaFinDesde);
        return ResponseEntity.ok(pagina);
    }

    /**
     * Método GET que llama al servicio para buscar eventos por una consulta de texto.
     * 
     * @param q Consulta de texto para buscar en el título, localización y categoría de los eventos.
     * @param limit Número máximo de resultados a devolver (opcional, por defecto 10).
     * @return ResponseEntity con la lista de eventos encontrados y el estado HTTP 200 (OK).
     */
    @GetMapping("/search")
    public ResponseEntity<List<EventoResponse>> buscarEventos(@RequestParam(name = "q", required = false) String q, @RequestParam(name = "limit", defaultValue = "10") int limit) {
        List<EventoResponse> resultados = eventoService.buscarEventos(q, limit);
        return ResponseEntity.ok(resultados);
    }

    /**
     * Método GET que llama al servicio para obtener eventos filtrados por categorías.
     * 
     * @param categorias Lista de IDs de categorías para filtrar los eventos (opcional).
     * @return ResponseEntity con la lista de eventos encontrados y el estado HTTP 200 (OK).
     */
    @GetMapping("/filter-by-categories")
    public ResponseEntity<List<EventoResponse>> obtenerEventosPorCategorias(@RequestParam(name = "categorias", required = false) List<Long> categorias) {
        List<EventoResponse> eventos = eventoService.obtenerEventosPorCategorias(categorias);
        return ResponseEntity.ok(eventos);
    }

    /**
     * Método GET que llama al servicio para contar el número total de eventos.
     * 
     * @return ResponseEntity con la cantidad total de eventos y el estado HTTP 200 (OK).
     */
    @GetMapping("/count")
    public ResponseEntity<Long> contarEventos() {
        long cantidad = eventoService.contarEventos();
        return ResponseEntity.ok(cantidad);
    }
}