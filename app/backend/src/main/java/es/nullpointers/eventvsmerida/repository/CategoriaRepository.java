package es.nullpointers.eventvsmerida.repository;

import es.nullpointers.eventvsmerida.entity.Categoria;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

/**
 * Repositorio que establece la comunicacion con la base de datos
 * para la entidad Categoria.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
@Repository
public interface CategoriaRepository extends JpaRepository<Categoria, Long> {
}