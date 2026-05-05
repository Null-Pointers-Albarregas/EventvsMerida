package es.nullpointers.eventvsmerida.utils;

/**
 * Clase de utilidades para el manejo de textos.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
public class TextoUtils {

    /**
     * Convierte el texto a minusculas y elimina espacios en blanco al inicio y al final.
     *
     * @param texto Texto a normalizar.
     * @return Texto normalizado o null si el texto es nulo o vacio.
     */
    public static String normalizarTexto(String texto) {
        return texto == null || texto.isBlank() ? null : texto.trim().toLowerCase();
    }

    /**
     * Capitaliza la primera letra de cada palabra en el texto.
     *
     * @param texto Texto a capitalizar.
     * @return Texto capitalizado o null si el texto es nulo o vacio.
     */
    public static String capitalizarTexto(String texto) {
        if (texto == null || texto.isBlank()) return null;

        String[] palabras = texto.trim().split("\\s+");
        String resultado = "";
        for (int i = 0; i < palabras.length; i++) {
            if (i > 0) resultado += " ";
            resultado += palabras[i].substring(0, 1).toUpperCase() + palabras[i].substring(1).toLowerCase();
        }

        return resultado;
    }
}