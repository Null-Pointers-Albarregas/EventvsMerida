package es.nullpointers.eventvsmerida.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;

import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.OffsetDateTime;

@Getter
@Setter
@Entity
@Table(name = "\"Evento\"")
public class Evento {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", nullable = false)
    private Long id;

    @NotNull
    @Column(name = "titulo", nullable = false, length = Integer.MAX_VALUE)
    private String titulo;

    @NotNull
    @Column(name = "descripcion", nullable = false, length = Integer.MAX_VALUE)
    private String descripcion;

    @NotNull
    @Column(name = "fecha_inicio", nullable = false)
    private LocalDateTime fechaInicio;

    @NotNull
    @Column(name = "fecha_fin", nullable = false)
    private LocalDateTime fechaFin;

    @NotNull
    @Column(name = "localizacion", nullable = false, length = Integer.MAX_VALUE)
    private String localizacion;

    @Column(name = "latitud", nullable = false)
    private Double latitud;

    @Column(name = "longitud", nullable = false)
    private Double longitud;

    @NotNull
    @Column(name = "foto", nullable = false, length = Integer.MAX_VALUE)
    private String foto;

    @NotNull
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @OnDelete(action = OnDeleteAction.SET_DEFAULT)
    @JoinColumn(name = "id_usuario", nullable = false)
    private Usuario usuario;

    @NotNull
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @OnDelete(action = OnDeleteAction.SET_DEFAULT)
    @JoinColumn(name = "id_categoria", nullable = false)
    private Categoria categoria;
}