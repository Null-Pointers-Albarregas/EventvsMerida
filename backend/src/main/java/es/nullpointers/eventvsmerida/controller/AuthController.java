package es.nullpointers.eventvsmerida.controller;

import es.nullpointers.eventvsmerida.dto.request.LoginRequest;
import es.nullpointers.eventvsmerida.dto.response.UsuarioResponse;
import es.nullpointers.eventvsmerida.service.UsuarioService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/auth")
@Slf4j
public class AuthController {
    private final AuthenticationManager authenticationManager;
    private final UsuarioService usuarioService;

    /**
     * Endpoint para iniciar sesión. Si el parámetro "admin" es true, solo permitirá el acceso a usuarios con rol de administrador.
     * 
     * @param loginRequest DTO con email y contraseña
     * @param admin indica si se requiere rol de administrador para el acceso
     * @param request objeto HttpServletRequest para gestionar la sesión
     * @return ResponseEntity con los datos del usuario logeado o error si no se cumplen las condiciones de autenticación/rol
     */
    @PostMapping("/login")
    public ResponseEntity<UsuarioResponse> login(
            @Valid @RequestBody LoginRequest loginRequest,
            @RequestParam(name = "admin", required = false, defaultValue = "false") boolean admin,
            HttpServletRequest request) {

        Authentication authentication = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(loginRequest.email(), loginRequest.password())
        );

        boolean isAdmin = authentication.getAuthorities().stream()
                .anyMatch(a -> "Administrador".equalsIgnoreCase(a.getAuthority()));

        if (admin && !isAdmin) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Solo administradores pueden iniciar sesión en el panel");
        }

        SecurityContextHolder.getContext().setAuthentication(authentication);
        request.getSession(true); // crea JSESSIONID

        UsuarioResponse usuarioLogeado = usuarioService.obtenerUsuarioPorEmail(loginRequest.email());
        return ResponseEntity.ok(usuarioLogeado);
    }

    /**
     * Endpoint para verificar si el usuario tiene una sesión activa. Retorna 200 OK si el usuario está autenticado, o 401 UNAUTHORIZED si no lo está.
     * 
     * @param authentication objeto Authentication inyectado por Spring Security, representa la autenticación actual del usuario
     * @return ResponseEntity sin cuerpo, con estado 200 OK si el usuario está autenticado o 401 UNAUTHORIZED si no lo está
     */
    @GetMapping("/session")
    public ResponseEntity<Void> session(Authentication authentication) {
        if (authentication == null || !authentication.isAuthenticated()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        return ResponseEntity.ok().build();
    }

    /**
     * Endpoint para cerrar sesión. Limpia el contexto de seguridad y invalida la sesión HTTP.
     * 
     * @param request objeto HttpServletRequest para gestionar la sesión
     * @return ResponseEntity sin cuerpo, con estado 204 NO CONTENT después de cerrar sesión exitosamente
     */
    @PostMapping("/logout")
    public ResponseEntity<Void> logout(HttpServletRequest request) {
        SecurityContextHolder.clearContext();
        var session = request.getSession(false);
        if (session != null) session.invalidate();
        return ResponseEntity.noContent().build();
    }
}