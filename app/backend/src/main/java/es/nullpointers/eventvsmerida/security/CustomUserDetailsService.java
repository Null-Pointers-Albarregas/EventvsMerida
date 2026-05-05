package es.nullpointers.eventvsmerida.security;

import es.nullpointers.eventvsmerida.entity.Usuario;
import es.nullpointers.eventvsmerida.repository.UsuarioRepository;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.jspecify.annotations.NullMarked;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

/**
 * Servicio personalizado para cargar los detalles del usuario desde la base de datos.
 * Implementa la interfaz UserDetailsService de Spring Security para proporcionar
 * lógica de autenticación personalizada.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
@Service
@RequiredArgsConstructor
public class CustomUserDetailsService implements UserDetailsService {
    private final UsuarioRepository usuarioRepository;

    /**
     * Carga los detalles del usuario por su email.
     *
     * @param email el email del usuario que se desea cargar.
     * @return un objeto UserDetails que contiene la información del usuario para la autenticación.
     * @throws UsernameNotFoundException si el usuario con el email proporcionado no se encuentra en la base de datos.
     */
    @NullMarked
    @Transactional
    @Override
    public UserDetails loadUserByUsername(String email) throws UsernameNotFoundException {
        Usuario usuario = usuarioRepository.findByEmail(email).orElseThrow(() -> new UsernameNotFoundException("Credenciales inválidas"));
        String rol = usuario.getRol().getNombre();

        return User.builder()
                .username(usuario.getEmail())
                .password(usuario.getPassword())
                .authorities(rol)
                .build();
    }
}