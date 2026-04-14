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

    @PostMapping("/guardar")
    public ResponseEntity<Void> guardarUsuarioEvento(@Valid @RequestBody UsuarioEventoRequest request) {
        usuarioEventoService.guardarUsuarioEvento(request);
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    @DeleteMapping("/eliminar")
    public ResponseEntity<Void> eliminarUsuarioEvento(@Valid @RequestBody UsuarioEventoRequest request) {
        usuarioEventoService.eliminarUsuarioEvento(request);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/guardados")
    public ResponseEntity<List<EventoResponse>> obtenerEventosGuardadosPorUsuario(
            @RequestParam @NotBlank @Email String emailUsuario) {
        List<EventoResponse> eventos = usuarioEventoService.obtenerEventosGuardadosPorUsuario(emailUsuario);
        return ResponseEntity.ok(eventos);
    }
}