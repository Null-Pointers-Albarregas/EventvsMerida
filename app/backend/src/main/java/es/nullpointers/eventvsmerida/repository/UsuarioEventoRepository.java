package es.nullpointers.eventvsmerida.repository;

import es.nullpointers.eventvsmerida.entity.UsuarioEvento;
import es.nullpointers.eventvsmerida.entity.UsuarioEventoId;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * Repositorio que establece la comunicacion con la base de datos
 * para la entidad UsuarioEvento.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
@Repository
public interface UsuarioEventoRepository extends JpaRepository<UsuarioEvento, UsuarioEventoId> {
    List<UsuarioEvento> findByIdIdUsuario(Long idUsuario);
}