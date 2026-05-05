package es.nullpointers.eventvsmerida.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;

@Getter
@Setter
@Entity
@Table(name = "\"Usuario-Evento\"")
public class UsuarioEvento {
    @EmbeddedId
    private UsuarioEventoId id;

    @MapsId("idUsuario")
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @OnDelete(action = OnDeleteAction.SET_DEFAULT)
    @JoinColumn(name = "id_usuario", nullable = false)
    private Usuario usuario;

    @MapsId("idEvento")
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @OnDelete(action = OnDeleteAction.SET_DEFAULT)
    @JoinColumn(name = "id_evento", nullable = false)
    private Evento evento;
}