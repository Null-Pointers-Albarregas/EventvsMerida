package es.nullpointers.eventvsmerida.exception;

/**
 * Excepción lanzada cuando hay un error de validación con la imagen o URL del evento.
 * 
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
public class EventoFotoImagenException extends RuntimeException {
    public EventoFotoImagenException(String message) {
        super(message);
    }
}