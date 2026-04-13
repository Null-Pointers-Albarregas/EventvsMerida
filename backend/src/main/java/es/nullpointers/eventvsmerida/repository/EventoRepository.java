package es.nullpointers.eventvsmerida.repository;

import es.nullpointers.eventvsmerida.entity.Evento;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.time.LocalDateTime;
import java.util.Optional;

/**
 * Repositorio que establece la comunicacion con la base de datos
 * para la entidad Evento.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
@Repository
public interface EventoRepository extends JpaRepository<Evento, Long> {
    boolean existsByTituloAndFechaInicioAndFechaFin(String titulo, LocalDateTime fechaInicio, LocalDateTime fechaFin);
    Optional<Evento> findByTituloAndFechaInicioAndFechaFin(String titulo, LocalDateTime fechaInicio, LocalDateTime fechaFin);
}