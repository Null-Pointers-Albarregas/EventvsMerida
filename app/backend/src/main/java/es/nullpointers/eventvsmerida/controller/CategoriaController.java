package es.nullpointers.eventvsmerida.controller;

import es.nullpointers.eventvsmerida.dto.request.CategoriaRequest;
import es.nullpointers.eventvsmerida.dto.response.CategoriaResponse;
import es.nullpointers.eventvsmerida.service.CategoriaService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Controlador REST que recibe las peticiones HTTP relacionadas con la
 * entidad Categoria y las delega al servicio correspondiente.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
@Slf4j
@RestController
@RequiredArgsConstructor
@RequestMapping("/api/categorias")
public class CategoriaController {
    private final CategoriaService categoriaService;

    // ============
    // Metodos CRUD
    // ============

    /**
     * Metodo GET que llama al servicio para obtener todas las categorias.
     *
     * @return ResponseEntity con la categoria creada y el estado HTTP 200 (OK).
     */
    @GetMapping("/all")
    public ResponseEntity<List<CategoriaResponse>> obtenerCategorias() {
        List<CategoriaResponse> categorias = categoriaService.obtenerCategorias();
        return ResponseEntity.ok(categorias);
    }

    /**
     * Metodo GET que llama al servicio para obtener una categoria por su ID.
     *
     * @param id ID de la categoria a obtener.
     * @return ResponseEntity con la categoria encontrada y el estado HTTP 200 (OK).
     */
    @GetMapping("/{id}")
    public ResponseEntity<CategoriaResponse> obtenerCategoriaPorId(@PathVariable Long id) {
        CategoriaResponse categoriaObtenida = categoriaService.obtenerCategoriaPorId(id);
        return ResponseEntity.ok(categoriaObtenida);
    }

    /**
     * Metodo POST que llama al servicio para crear una nueva categoria.
     *
     * @param categoriaCrearRequest DTO con los datos de la categoria a crear.
     * @return ResponseEntity con la categoria creada y el estado HTTP 201 (CREATED).
     */
    @PostMapping("/add")
    public ResponseEntity<CategoriaResponse> crearCategoria(@Valid @RequestBody CategoriaRequest categoriaCrearRequest) {
        CategoriaResponse categoriaNueva = categoriaService.crearCategoria(categoriaCrearRequest);
        return ResponseEntity.status(HttpStatus.CREATED).body(categoriaNueva);
    }

    /**
     * Metodo DELETE que llama al servicio para eliminar una categoria por su ID.
     *
     * @param id ID de la categoria a eliminar.
     * @return ResponseEntity con el estado HTTP 204 (NO CONTENT).
     */
    @DeleteMapping("/delete/{id}")
    public ResponseEntity<Void> eliminarCategoria(@PathVariable Long id) {
        categoriaService.eliminarCategoria(id);
        return ResponseEntity.noContent().build();
    }

    /**
     * Metodo PUT que llama al servicio para actualizar una categoria por su ID.
     *
     * @param id ID de la categoria a actualizar.
     * @param categoriaActualizarRequest DTO con los datos de la categoria a actualizar.
     * @return ResponseEntity con la categoria actualizada y el estado HTTP 200 (OK).
     */
    @PutMapping("/update/{id}")
    public ResponseEntity<CategoriaResponse> actualizarCategoria(@PathVariable Long id, @Valid @RequestBody CategoriaRequest categoriaActualizarRequest) {
        CategoriaResponse categoriaActualizada = categoriaService.actualizarCategoria(id, categoriaActualizarRequest);
        return ResponseEntity.ok(categoriaActualizada);
    }

    // =========================
    // Metodos Lógica de Negocio
    // =========================

    /**
     * Metodo GET que llama al servicio para contar el numero total de categorias.
     * 
     * @return ResponseEntity con la cantidad de categorias y el estado HTTP 200 (OK).
     */
    @GetMapping("/count")
    public ResponseEntity<Long> contarCategorias() {
        long cantidad = categoriaService.contarCategorias();
        return ResponseEntity.ok(cantidad);
    }
}