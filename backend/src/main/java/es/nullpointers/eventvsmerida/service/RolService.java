package es.nullpointers.eventvsmerida.service;

import es.nullpointers.eventvsmerida.dto.request.RolRequest;
import es.nullpointers.eventvsmerida.dto.response.RolResponse;
import es.nullpointers.eventvsmerida.entity.Rol;
import es.nullpointers.eventvsmerida.mapper.RolMapper;
import es.nullpointers.eventvsmerida.repository.RolRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.NoSuchElementException;

/**
 * Servicio para gestionar la logica de negocio relacionada con la
 * entidad Rol.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
@Slf4j
@RequiredArgsConstructor
@Service
public class RolService {
    private final RolRepository rolRepository;

    // ============
    // Metodos CRUD
    // ============

    /**
     * Metodo para obtener todos los roles.
     *
     * @return Lista de roles.
     */
    public List<RolResponse> obtenerRoles() {
        List<Rol> roles = rolRepository.findAll();
        List<RolResponse> rolesResponse = new ArrayList<>();

        for (Rol rol : roles) {
            rolesResponse.add(RolMapper.convertirAResponse(rol));
        }

        return rolesResponse;
    }

    /**
     * Metodo para obtener un rol por su ID.
     *
     * @param id ID del rol a obtener.
     * @return Rol encontrado.
     */
    public RolResponse obtenerRolPorId(Long id) {
        Rol rolObtenido = obtenerRolPorIdOExcepcion(id, "Error en RolService.obtenerRolPorId: No se encontró el rol con id " + id);
        return RolMapper.convertirAResponse(rolObtenido);
    }

    /**
     * Metodo para crear un nuevo rol.
     *
     * @param rolRequest Datos del rol a crear.
     * @return Rol creado.
     */
    public RolResponse crearRol(RolRequest rolRequest) {
        Rol rolNuevo = RolMapper.convertirAEntidad(rolRequest);
        Rol rolCreado = rolRepository.save(rolNuevo);
        return RolMapper.convertirAResponse(rolCreado);
    }

    /**
     * Metodo para eliminar un rol por su ID.
     *
     * @param id ID del rol a eliminar.
     */
    public void eliminarRol(Long id) {
        Rol rol = obtenerRolPorIdOExcepcion(id, "Error en RolService.eliminarRol: No se encontró el rol con id " + id);
        rolRepository.delete(rol);
    }

    /**
     * Metodo para actualizar un rol existente.
     *
     * @param id ID del rol a actualizar.
     * @param rolRequest Datos actualizados del rol.
     * @return Rol actualizado.
     */
    public RolResponse actualizarRol(Long id, RolRequest rolRequest) {
        Rol rolExistente = obtenerRolPorIdOExcepcion(id, "Error en RolService.actualizarRol: No se encontró el rol con id " + id);

        rolExistente.setNombre(rolRequest.nombre());
        Rol rolActualizado = rolRepository.save(rolExistente);

        return RolMapper.convertirAResponse(rolActualizado);
    }

    // =========================
    // Metodos Lógica de Negocio
    // =========================

    /**
     * Metodo para contar el numero total de roles.
     * 
     * @return Número total de roles.
     */
    public long contarRoles() {
        return rolRepository.count();
    }

    // ==================
    // Metodos Auxiliares
    // ==================

    /**
     * Metodo privado para obtener un rol por su ID o lanzar una excepcion personalizada si no se encuentra.
     *
     * @param id ID del rol a obtener.
     * @param mensajeError Mensaje de error para la excepcion.
     * @return Rol encontrado.
     */
    public Rol obtenerRolPorIdOExcepcion(Long id, String mensajeError) {
        return rolRepository.findById(id).orElseThrow(() -> new NoSuchElementException(mensajeError));
    }
}