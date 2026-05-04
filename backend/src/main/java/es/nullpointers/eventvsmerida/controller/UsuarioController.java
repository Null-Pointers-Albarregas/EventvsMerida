package es.nullpointers.eventvsmerida.controller;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import es.nullpointers.eventvsmerida.dto.request.UsuarioActualizarRequest;
import es.nullpointers.eventvsmerida.dto.request.UsuarioCrearRequest;
import es.nullpointers.eventvsmerida.dto.response.UsuarioResponse;
import es.nullpointers.eventvsmerida.service.UsuarioService;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

/**
 * Controlador REST que recibe las peticiones HTTP relacionadas con la
 * entidad Usuario y las delega al servicio correspondiente.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
@Slf4j
@RestController
@RequiredArgsConstructor
@RequestMapping("/api/usuarios")
public class UsuarioController {
    private final UsuarioService usuarioService;

    // ============
    // Metodos CRUD
    // ============

    /**
     * Metodo GET que llama al servicio para obtener todos los usuarios.
     *
     * @return ResponseEntity con la lista de usuarios y el estado HTTP 200 (OK).
     */
    @GetMapping("/all")
    public ResponseEntity<List<UsuarioResponse>> obtenerUsuarios() {
        List<UsuarioResponse> usuarios = usuarioService.obtenerUsuarios();
        return ResponseEntity.ok(usuarios);
    }

    /**
     * Metodo GET que llama al servicio para obtener un usuario por su ID.
     *
     * @param id ID del usuario a obtener.
     * @return ResponseEntity con el usuario encontrado y el estado HTTP 200 (OK).
     */
    @GetMapping("/{id}")
    public ResponseEntity<UsuarioResponse> obtenerUsuarioPorId(@PathVariable Long id) {
        UsuarioResponse usuarioObtenido = usuarioService.obtenerUsuarioPorId(id);
        return ResponseEntity.ok(usuarioObtenido);
    }

    /**
     * Metodo POST que llama al servicio para crear un nuevo usuario.
     *
     * @param jsonUsuario DTO con los datos del usuario a crear.
     * @param foto Imagen de perfil opcional.
     * @return ResponseEntity con el usuario creado y el estado HTTP 201 (CREATED).
     */
    @PostMapping(value = "/add", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<UsuarioResponse> crearUsuario(
            @Valid @RequestPart("usuario") String jsonUsuario,
            @RequestPart(value = "foto", required = false) MultipartFile foto
    ) throws JsonProcessingException {
        ObjectMapper mapper = new ObjectMapper();
        mapper.registerModule(new JavaTimeModule());

        UsuarioCrearRequest request = mapper.readValue(jsonUsuario, UsuarioCrearRequest.class);
        UsuarioResponse usuarioNuevo = usuarioService.crearUsuario(request, foto);
        return ResponseEntity.status(HttpStatus.CREATED).body(usuarioNuevo);
    }

    /**
     * Metodo DELETE que llama al servicio para eliminar un usuario por su ID.
     *
     * @param id ID del usuario a eliminar.
     * @return ResponseEntity con el estado HTTP 204 (NO CONTENT).
     */
    @DeleteMapping("/delete/{id}")
    public ResponseEntity<Void> eliminarUsuario(@PathVariable Long id) {
        usuarioService.eliminarUsuario(id);
        return ResponseEntity.noContent().build();
    }

    /**
     * Metodo PUT que llama al servicio para actualizar un usuario existente.
     *
     * @param id ID del usuario a actualizar.
     * @param jsonUsuario DTO con los datos del usuario a actualizar.
     * @param foto Imagen de perfil opcional.
     * @return ResponseEntity con el usuario actualizado y el estado HTTP 200 (OK).
     */
    @PutMapping(value = "/update/{id}", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<UsuarioResponse> actualizarUsuario(
            @PathVariable Long id,
            @Valid @RequestPart("usuario") String jsonUsuario,
            @RequestPart(value = "foto", required = false) MultipartFile foto
    ) throws JsonProcessingException {
        ObjectMapper mapper = new ObjectMapper();
        mapper.registerModule(new JavaTimeModule());

        UsuarioActualizarRequest request = mapper.readValue(jsonUsuario, UsuarioActualizarRequest.class);
        UsuarioResponse usuarioActualizado = usuarioService.actualizarUsuario(id, request, foto);
        return ResponseEntity.ok(usuarioActualizado);
    }

    // ============================
    // Metodos de Lógica de Negocio
    // ============================

    /**
     * Metodo GET que llama al servicio para contar el número de usuarios registrados en la plataforma.
     * 
     * @return ResponseEntity con la cantidad de usuarios registrados y el estado HTTP 200 (OK).
     */
    @GetMapping("/count/registered")
    public ResponseEntity<Long> contarRegistrados() {
        return ResponseEntity.ok(usuarioService.contarUsuariosPorRol(1L));
    }

    /**
     * Metodo GET que llama al servicio para contar el número de organizadores registrados en la plataforma.
     * 
     * @return ResponseEntity con la cantidad de organizadores registrados y el estado HTTP 200 (OK).
     */
    @GetMapping("/count/organizers")
    public ResponseEntity<Long> contarOrganizadores() {
        return ResponseEntity.ok(usuarioService.contarUsuariosPorRol(2L));
    }

    /**
     * Metodo GET que llama al servicio para obtener la lista de usuarios registrados en la plataforma.
     * 
     * @return ResponseEntity con la lista de usuarios registrados y el estado HTTP 200 (OK).
     */
    @GetMapping("/registered")
    public ResponseEntity<List<UsuarioResponse>> obtenerUsuariosRegistrados() {
        List<UsuarioResponse> usuarios = usuarioService.obtenerUsuariosPorRol(1L);
        return ResponseEntity.ok(usuarios);
    }

    /**
     * Metodo GET que llama al servicio para obtener la lista de organizadores registrados en la plataforma.
     * 
     * @return ResponseEntity con la lista de organizadores registrados y el estado HTTP 200 (OK).
     */
    @GetMapping("/organizers")
    public ResponseEntity<List<UsuarioResponse>> obtenerUsuariosOrganizadores() {
        List<UsuarioResponse> usuarios = usuarioService.obtenerUsuariosPorRol(2L);
        return ResponseEntity.ok(usuarios);
    }
}