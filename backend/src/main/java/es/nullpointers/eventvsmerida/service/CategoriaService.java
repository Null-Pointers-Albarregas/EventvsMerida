package es.nullpointers.eventvsmerida.service;

import es.nullpointers.eventvsmerida.dto.request.CategoriaRequest;
import es.nullpointers.eventvsmerida.dto.response.CategoriaResponse;
import es.nullpointers.eventvsmerida.entity.Categoria;
import es.nullpointers.eventvsmerida.mapper.CategoriaMapper;
import es.nullpointers.eventvsmerida.repository.CategoriaRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.NoSuchElementException;

/**
 * Servicio para gestionar la logica de negocio relacionada con la
 * entidad Categoria.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
@Slf4j
@RequiredArgsConstructor
@Service
public class CategoriaService {
    private final CategoriaRepository categoriaRepository;

    // ============
    // Metodos CRUD
    // ============

    /**
     * Metodo para obtener todas las categorias.
     *
     * @return Lista de categorias.
     */
    public List<CategoriaResponse> obtenerCategorias() {
        List<Categoria> categorias = categoriaRepository.findAll();
        List<CategoriaResponse> categoriasResponse = new ArrayList<>();

        for (Categoria categoria : categorias) {
            categoriasResponse.add(CategoriaMapper.convertirAResponse(categoria));
        }

        return categoriasResponse;
    }

    /**
     * Metodo para obtener una categoria por su ID.
     *
     * @param id ID de la categoria a obtener.
     * @return Categoria encontrada.
     */
    public CategoriaResponse obtenerCategoriaPorId(Long id) {
        Categoria categoriaObtenida = obtenerCategoriaPorIdOExcepcion(id, "Error en CategoriaService.obtenerCategoriaPorId: No se encontró la categoria con id " + id);
        return CategoriaMapper.convertirAResponse(categoriaObtenida);
    }

    /**
     * Metodo para crear una nueva categoria.
     *
     * @param categoriaRequest Datos de la categoria a crear.
     * @return Categoria creada.
     */
    public CategoriaResponse crearCategoria(CategoriaRequest categoriaRequest) {
        Categoria categoriaNueva = CategoriaMapper.convertirAEntidad(categoriaRequest);
        Categoria categoriaCreada = categoriaRepository.save(categoriaNueva);
        return CategoriaMapper.convertirAResponse(categoriaCreada);
    }

    /**
     * Metodo para eliminar una categoria por su ID.
     *
     * @param id ID de la categoria a eliminar.
     */
    public void eliminarCategoria(Long id) {
        Categoria categoria = obtenerCategoriaPorIdOExcepcion(id, "Error en CategoriaService.eliminarCategoria: No se encontró la categoria con id " + id);
        categoriaRepository.delete(categoria);
    }

    /**
     * Metodo para actualizar una categoria por su ID.
     *
     * @param id ID de la categoria a actualizar.
     * @param categoriaRequest Datos de la categoria a actualizar.
     * @return Categoria actualizada.
     */
    public CategoriaResponse actualizarCategoria(Long id, CategoriaRequest categoriaRequest) {
        Categoria categoriaExistente = obtenerCategoriaPorIdOExcepcion(id, "Error en CategoriaService.actualizarCategoria: No se encontró la categoria con id: " + id);

        categoriaExistente.setNombre(categoriaRequest.nombre());
        Categoria categoriaActualizada = categoriaRepository.save(categoriaExistente);

        return CategoriaMapper.convertirAResponse(categoriaActualizada);
    }

    // ==================
    // Metodos Auxiliares
    // ==================

    /**
     * Metodo privado para obtener una categoria por su ID o lanzar una excepcion si no se encuentra.
     *
     * @param id ID de la categoria a obtener.
     * @param mensajeError Mensaje de error para la excepcion.
     * @return Categoria encontrada.
     */
    public Categoria obtenerCategoriaPorIdOExcepcion(Long id, String mensajeError) {
        return categoriaRepository.findById(id).orElseThrow(() -> new NoSuchElementException(mensajeError));
    }
}