package es.nullpointers.eventvsmerida.service;

import es.nullpointers.eventvsmerida.dto.request.UsuarioActualizarRequest;
import es.nullpointers.eventvsmerida.dto.request.UsuarioCrearRequest;
import es.nullpointers.eventvsmerida.dto.response.UsuarioResponse;
import es.nullpointers.eventvsmerida.entity.Rol;
import es.nullpointers.eventvsmerida.entity.Usuario;
import es.nullpointers.eventvsmerida.mapper.UsuarioMapper;
import es.nullpointers.eventvsmerida.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.ArrayList;
import java.util.List;
import java.util.NoSuchElementException;

/**
 * Servicio para gestionar la logica de negocio relacionada con la
 * entidad Usuario.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
@Slf4j
@RequiredArgsConstructor
@Service
public class UsuarioService {
    private final UsuarioRepository usuarioRepository;
    private final RolService rolService;
    private final PasswordEncoder passwordEncoder;

    // ============
    // Metodos CRUD
    // ============

    /**
     * Metodo para obtener todos los usuarios.
     *
     * @return Lista de usuarios.
     */
    public List<UsuarioResponse> obtenerUsuarios() {
        List<Usuario> usuarios = usuarioRepository.findAll();
        List<UsuarioResponse> usuariosResponse = new ArrayList<>();

        for (Usuario usuario : usuarios) {
            usuariosResponse.add(UsuarioMapper.convertirAResponse(usuario));
        }

        return usuariosResponse;
    }

    /**
     * Metodo para obtener un usuario por su ID.
     *
     * @param id ID del usuario a obtener.
     * @return Usuario encontrado.
     */
    public UsuarioResponse obtenerUsuarioPorId(Long id) {
        Usuario usuarioObtenido = obtenerUsuarioPorIdOExcepcion(id, "Error en UsuarioService.obtenerUsuarioPorId: No se encontró el usuario con id " + id);
        return UsuarioMapper.convertirAResponse(usuarioObtenido);
    }

    /**
     * Metodo para crear un nuevo usuario.
     *
     * @param usuarioRequest Datos del usuario a crear.
     * @return Usuario creado.
     */
    public UsuarioResponse crearUsuario(UsuarioCrearRequest usuarioRequest) {
        // Se hacen las comprobaciones necesarias para evitar errores de integridad de datos
        Rol rol = rolService.obtenerRolPorIdOExcepcion(usuarioRequest.idRol(), "Error en UsuarioService.crearUsuario: No se encontró el rol con id " + usuarioRequest.idRol());

        // Se convierte el DTO a entidad y se codifica la contraseña
        Usuario usuarioNuevo = UsuarioMapper.convertirAEntidad(usuarioRequest, rol);
        usuarioNuevo.setPassword(passwordEncoder.encode(usuarioNuevo.getPassword()));

        // Se guarda el nuevo usuario en la base de datos
        Usuario usuarioCreado = usuarioRepository.save(usuarioNuevo);

        // Se devuelve el usuario creado convertido a response
        return UsuarioMapper.convertirAResponse(usuarioCreado);
    }

    /**
     * Metodo para eliminar un usuario por su ID.
     *
     * @param id ID del usuario a eliminar.
     */
    public void eliminarUsuario(Long id) {
        Usuario usuario = obtenerUsuarioPorIdOExcepcion(id, "Error en UsuarioService.eliminarUsuario: No se encontró el usuario con id " + id);
        usuarioRepository.delete(usuario);
    }

    /**
     * Metodo para actualizar un usuario existente.
     *
     * @param id ID del usuario a actualizar.
     * @param usuarioRequest Datos actualizados del usuario.
     * @return Usuario actualizado.
     */
    public UsuarioResponse actualizarUsuario(Long id, UsuarioActualizarRequest usuarioRequest) {
        Usuario usuarioExistente = obtenerUsuarioPorIdOExcepcion(id, "Error en UsuarioService.actualizarUsuario: No se encontró el usuario con id " + id);

        // Se actualizan solo los campos que no sean nulos en el request, permitiendo actualizaciones parciales
        if (usuarioRequest.nombre() != null) {
            usuarioExistente.setNombre(usuarioRequest.nombre());
        }

        if (usuarioRequest.apellidos() != null) {
            usuarioExistente.setApellidos(usuarioRequest.apellidos());
        }

        if (usuarioRequest.fechaNacimiento() != null) {
            usuarioExistente.setFechaNacimiento(usuarioRequest.fechaNacimiento());
        }

        if (usuarioRequest.email() != null) {
            usuarioExistente.setEmail(usuarioRequest.email());
        }

        if (usuarioRequest.telefono() != null) {
            usuarioExistente.setTelefono(usuarioRequest.telefono());
        }

        if (usuarioRequest.password() != null) {
            usuarioExistente.setPassword(passwordEncoder.encode(usuarioRequest.password()));
        }

        if (usuarioRequest.idRol() != null) {
            Rol rol = rolService.obtenerRolPorIdOExcepcion(usuarioRequest.idRol(), "Error en UsuarioService.actualizarUsuario: No se encontró el rol con id " + usuarioRequest.idRol());
            usuarioExistente.setRol(rol);
        }

        // Se guarda el usuario actualizado en la base de datos
        Usuario usuarioActualizado = usuarioRepository.save(usuarioExistente);

        // Se devuelve el usuario actualizado convertido a response
        return UsuarioMapper.convertirAResponse(usuarioActualizado);
    }

    // =================
    // Metodos de Lógica
    // =================

    /**
     * Metodo para iniciar sesión a un usuario con su email y contraseña.
     *
     * @param email    Email del usuario a autenticar.
     * @param password Contraseña del usuario a autenticar.
     * @return Usuario logeado si las credenciales son correctas.
     */
    public UsuarioResponse login(String email, String password) {
        Usuario usuario = usuarioRepository.findByEmail(email).orElseThrow(() -> new NoSuchElementException("Error en UsuarioService.login: No se encontró el usuario con email " + email));

        if (!passwordEncoder.matches(password, usuario.getPassword())) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Credenciales inválidas");
        }

        log.info("Login exitoso para el usuario con email: {}", email);
        return UsuarioMapper.convertirAResponse(usuario);
    }

    // ==================
    // Metodos Auxiliares
    // ==================

    /**
     * Metodo para obtener un usuario por su ID o lanzar una excepcion
     * personalizada si no se encuentra.
     *
     * @param id ID del usuario a obtener.
     * @param mensajeError Mensaje de error para la excepcion.
     * @return Usuario encontrado.
     */
    public Usuario obtenerUsuarioPorIdOExcepcion(Long id, String mensajeError) {
        return usuarioRepository.findById(id).orElseThrow(() -> new NoSuchElementException(mensajeError));
    }
}