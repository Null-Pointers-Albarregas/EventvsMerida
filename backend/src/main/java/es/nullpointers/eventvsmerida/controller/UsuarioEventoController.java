package es.nullpointers.eventvsmerida.controller;

import es.nullpointers.eventvsmerida.dto.request.UsuarioEventoRequest;
import es.nullpointers.eventvsmerida.dto.response.EventoResponse;
import es.nullpointers.eventvsmerida.service.UsuarioEventoService;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Controlador REST que recibe las peticiones HTTP relacionadas con la
 * entidad UsuarioEvento y las delega al servicio correspondiente.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
@Slf4j
@Validated
@RestController
@RequestMapping("/api/usuario-eventos")
@RequiredArgsConstructor
public class UsuarioEventoController {
    private final UsuarioEventoService usuarioEventoService;

    /**
     * Guarda un evento como favorito para un usuario.
     * 
     * @param request Objeto que contiene el email del usuario y el ID del evento a guardar.
     * @return Respuesta HTTP con el estado de la operación (201 Created si se guarda correctamente).
     */
    @PostMapping("/guardar")
    public ResponseEntity<Void> guardarUsuarioEvento(@Valid @RequestBody UsuarioEventoRequest request) {
        usuarioEventoService.guardarUsuarioEvento(request);
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    /**
     * Elimina un evento guardado por un usuario.
     * 
     * @param request Objeto que contiene el email del usuario y el ID del evento a eliminar.
     * @return Respuesta HTTP con el estado de la operación (204 No Content si se elimina correctamente).
     */
    @DeleteMapping("/eliminar")
    public ResponseEntity<Void> eliminarUsuarioEvento(@Valid @RequestBody UsuarioEventoRequest request) {
        usuarioEventoService.eliminarUsuarioEvento(request);
        return ResponseEntity.noContent().build();
    }

    /**
     * Obtiene la lista de eventos guardados por un usuario.
     * 
     * @param emailUsuario El email del usuario para el cual se desean obtener los eventos guardados.
     * @return Respuesta HTTP con la lista de eventos guardados por el usuario (200 OK) o un error si el email es inválido.
     */
    @GetMapping("/guardados")
    public ResponseEntity<List<EventoResponse>> obtenerEventosGuardadosPorUsuario(@RequestParam @NotBlank @Email String emailUsuario) {
        List<EventoResponse> eventos = usuarioEventoService.obtenerEventosGuardadosPorUsuario(emailUsuario);
        return ResponseEntity.ok(eventos);
    }
}