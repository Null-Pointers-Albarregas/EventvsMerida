package es.nullpointers.eventvsmerida.controller;

import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import es.nullpointers.eventvsmerida.dto.request.EventoCrearRequest;
import es.nullpointers.eventvsmerida.dto.request.EventoImagenCrearRequest;
import es.nullpointers.eventvsmerida.dto.response.EventoResponse;
import es.nullpointers.eventvsmerida.dto.request.EventoActualizarRequest;
import es.nullpointers.eventvsmerida.service.EventoService;

import jakarta.validation.Valid;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.core.JsonProcessingException;

import java.util.List;

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
     * @param eventoCrearRequest DTO con los datos del evento a crear.
     * @return ResponseEntity con el evento creado y el estado HTTP 201 (Created).
     */
    @PostMapping("/add")
    public ResponseEntity<EventoResponse> crearEvento(@Valid @RequestBody EventoCrearRequest eventoCrearRequest) {
        EventoResponse eventoNuevo = eventoService.crearEvento(eventoCrearRequest);
        return ResponseEntity.status(HttpStatus.CREATED).body(eventoNuevo);
    }

    /**
     * Método POST que llama al servicio para crear un nuevo evento con archivo de imagen.
     * 
     * @param jsonEvento String con el JSON del evento a crear, que se convertirá a EventoImagenCrearRequest.
     * @param foto MultipartFile con la imagen del evento a crear.
     * @return ResponseEntity con el evento creado y el estado HTTP 201 (Created).
     * @throws JsonProcessingException
     */
    @PostMapping(value = "/addWithImage", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<EventoResponse> crearEventoConImagen(@Valid @RequestPart("evento")String jsonEvento, @RequestPart("foto") MultipartFile foto) throws JsonProcessingException {
        ObjectMapper mapper = new ObjectMapper();
        mapper.registerModule(new JavaTimeModule());

        EventoImagenCrearRequest request = mapper.readValue(jsonEvento, EventoImagenCrearRequest.class);
        EventoResponse eventoConImagenNuevo = eventoService.crearEventoConImagen(request, foto);

        return ResponseEntity.status(HttpStatus.CREATED).body(eventoConImagenNuevo);
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
     * Método PUT que llama al servicio para actualizar un evento existente.
     *
     * @param id ID del evento a actualizar.
     * @param eventoActualizarRequest DTO con los datos del evento a actualizar.
     * @return ResponseEntity con el evento actualizado y el estado HTTP 200 (OK).
     */
    @PutMapping("/update/{id}")
    public ResponseEntity<EventoResponse> actualizarEvento (@PathVariable Long id, @Valid @RequestBody EventoActualizarRequest eventoActualizarRequest) {
        EventoResponse eventoActualizado = eventoService.actualizarEvento(id, eventoActualizarRequest);
        return ResponseEntity.ok(eventoActualizado);
    }

    // =========================
    // Metodos Lógica de Negocio
    // =========================

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