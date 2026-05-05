package es.nullpointers.eventvsmerida.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

/**
 * Controlador para redirigir a la página de Swagger UI.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
@Controller
public class HomeController {

    /**
     * Metodo GET que redirige a la página de Swagger UI.
     *
     * @return String con la redirección a Swagger UI.
     */
    @GetMapping("/")
    public String home() {
        return "redirect:/swagger-ui.html";
    }
}