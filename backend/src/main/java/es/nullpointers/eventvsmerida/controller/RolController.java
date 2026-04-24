package es.nullpointers.eventvsmerida.controller;

import es.nullpointers.eventvsmerida.dto.request.RolRequest;
import es.nullpointers.eventvsmerida.dto.response.RolResponse;
import es.nullpointers.eventvsmerida.service.RolService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Controlador REST que recibe las peticiones HTTP relacionadas con la
 * entidad Rol y las delega al servicio correspondiente.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
@Slf4j
@RestController
@RequiredArgsConstructor
@RequestMapping("/api/roles")
public class RolController {
    private final RolService rolService;

    // ============
    // Metodos CRUD
    // ============

    /**
     * Metodo GET que llama al servicio para obtener todos los roles.
     *
     * @return ResponseEntity con la lista de roles y el estado HTTP 200 (OK).
     */
    @GetMapping("/all")
    public ResponseEntity<List<RolResponse>> obtenerRoles() {
        List<RolResponse> roles = rolService.obtenerRoles();
        return ResponseEntity.ok(roles);
    }

    /**
     * Metodo GET que llama al servicio para obtener un rol por su ID.
     *
     * @param id ID del rol a obtener.
     * @return ResponseEntity con el rol encontrado y el estado HTTP 200 (OK).
     */
    @GetMapping("/{id}")
    public ResponseEntity<RolResponse> obtenerRolPorId(@PathVariable Long id) {
        RolResponse rolObtenido = rolService.obtenerRolPorId(id);
        return ResponseEntity.ok(rolObtenido);
    }

    /**
     * Metodo POST que llama al servicio para crear un nuevo rol.
     *
     * @param rolCrearRequest DTO con los datos del rol a crear.
     * @return ResponseEntity con el rol creado y el estado HTTP 201 (CREATED).
     */
    @PostMapping("/add")
    public ResponseEntity<RolResponse> crearRol(@Valid @RequestBody RolRequest rolCrearRequest) {
        RolResponse rolNuevo = rolService.crearRol(rolCrearRequest);
        return ResponseEntity.status(HttpStatus.CREATED).body(rolNuevo);
    }

    /**
     * Metodo DELETE que llama al servicio para eliminar un rol por su ID.
     *
     * @param id ID del rol a eliminar.
     * @return ResponseEntity con el estado HTTP 204 (NO CONTENT).
     */
    @DeleteMapping("/delete/{id}")
    public ResponseEntity<Void> eliminarRol(@PathVariable Long id) {
        rolService.eliminarRol(id);
        return ResponseEntity.noContent().build();
    }

    /**
     * Metodo PUT que llama al servicio para actualizar un rol existente.
     *
     * @param id ID del rol a actualizar.
     * @param rolActualizarRequest DTO con los datos del rol a actualizar.
     * @return ResponseEntity con el rol actualizado y el estado HTTP 200 (OK).
     */
    @PutMapping("/update/{id}")
    public ResponseEntity<RolResponse> actualizarRol(@PathVariable Long id, @Valid @RequestBody RolRequest rolActualizarRequest) {
        RolResponse rolActualizado = rolService.actualizarRol(id, rolActualizarRequest);
        return ResponseEntity.ok(rolActualizado);
    }

    // =========================
    // Metodos Lógica de Negocio
    // =========================

    /**
     * Metodo GET que llama al servicio para contar la cantidad de roles existentes.
     * 
     * @return ResponseEntity con la cantidad de roles y el estado HTTP 200 (OK).
     */
    @GetMapping("/count")
    public ResponseEntity<Long> contarRoles() {
        long cantidad = rolService.contarRoles();
        return ResponseEntity.ok(cantidad);
    }
}