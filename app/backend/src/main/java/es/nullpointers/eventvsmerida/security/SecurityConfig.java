package es.nullpointers.eventvsmerida.security;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;

/**
 * Configuración de seguridad para la aplicación.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
@Configuration
public class SecurityConfig {

    /**
     * Bean para el codificador de contraseñas utilizando BCrypt.
     *
     * @return un PasswordEncoder que utiliza BCrypt para codificar las contraseñas.
     */
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    /**
     * Bean para el AuthenticationManager, que se utiliza para gestionar la autenticación de los usuarios.
     *
     * @param config la configuración de autenticación proporcionada por Spring Security.
     * @return un AuthenticationManager que se puede utilizar para autenticar a los usuarios.
     * @throws Exception si ocurre un error al obtener el AuthenticationManager de la configuración.
     */
    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration config) throws Exception {
        return config.getAuthenticationManager();
    }

    /**
     * Configura la cadena de filtros de seguridad para la aplicación.
     *
     * Reglas aplicadas (resumen):
     * - POST/PUT/DELETE sobre /api/eventos/** => Administrador u Organizador
     * - POST/PUT/DELETE de categorías (add/update/delete) => solo Administrador
     * - GET específicos de usuarios => solo Administrador
     * - /api/roles/** y Swagger => solo Administrador
     * - Resto de rutas => público
     *
     * @param http el objeto HttpSecurity utilizado para configurar la seguridad HTTP.
     * @return un SecurityFilterChain que define las reglas de seguridad para las solicitudes HTTP.
     */
    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) {
        http
            .csrf(AbstractHttpConfigurer::disable)
            .cors(Customizer.withDefaults())
            .authorizeHttpRequests(auth -> auth

                // Eventos: (POST/PUT/DELETE) -> Administrador u Organizador
                .requestMatchers(HttpMethod.POST, "/api/eventos/add").hasAnyAuthority("Administrador", "Organizador")
                .requestMatchers(HttpMethod.PUT,  "/api/eventos/update/*").hasAnyAuthority("Administrador", "Organizador")
                .requestMatchers(HttpMethod.DELETE, "/api/eventos/delete/*").hasAnyAuthority("Administrador", "Organizador")

                // Categorías: (POST/PUT/DELETE) -> solo Administrador
                .requestMatchers(HttpMethod.POST,   "/api/categorias/add").hasAuthority("Administrador")
                .requestMatchers(HttpMethod.PUT,    "/api/categorias/update/*").hasAuthority("Administrador")
                .requestMatchers(HttpMethod.DELETE, "/api/categorias/delete/*").hasAuthority("Administrador")

                // Usuarios: solo los GETs -> solo Administrador
                .requestMatchers(HttpMethod.GET,
                    "/api/usuarios/registered",
                    "/api/usuarios/organizers",
                    "/api/usuarios/count/registered",
                    "/api/usuarios/count/organizers",
                    "/api/usuarios/all"
                ).hasAuthority("Administrador")

                // Usuarios: GET con id -> Administrador y Registrado
                .requestMatchers(HttpMethod.GET,
                    "/api/usuarios/*"
                .hasAnyAuthority("Administrador", "Registrado")

                // Roles y swagger: solo Administrador
                .requestMatchers(
                    "/swagger-ui/**",
                    "/swagger-ui.html",
                    "/v3/api-docs/**",
                    "/api/roles/**"
                ).hasAuthority("Administrador")

                // Resto de rutas públicas
                .anyRequest().permitAll()
            )
            .formLogin(Customizer.withDefaults());

        return http.build();
    }
}
