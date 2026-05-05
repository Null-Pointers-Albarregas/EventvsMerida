package es.nullpointers.eventvsmerida.dto.request;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

/**
 * DTO para la solicitud de inicio de sesión.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
public record LoginRequest(
        @NotBlank
        @Email
        String email,

        @NotBlank
        @Pattern(
                regexp = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d).{8,}$",
                message = "La contraseña debe tener al menos 8 caracteres, una mayúscula, una minúscula y un número"
        )
        String password
) {}