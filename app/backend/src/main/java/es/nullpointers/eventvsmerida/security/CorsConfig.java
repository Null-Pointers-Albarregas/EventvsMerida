package es.nullpointers.eventvsmerida.security;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * Configuración de CORS para permitir solicitudes desde web.
 * 
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
@Configuration
public class CorsConfig {
    private static final String[] ALLOWED_ORIGINS = {
        "https://eventvsmerida-admin.vercel.app",
        "http://127.0.0.1:5500",
        "http://127.0.0.1:5501",
    };
    private static final String[] ALLOWED_METHODS = { "GET", "POST", "PUT", "DELETE", "OPTIONS" };
    private static final String[] ALLOWED_HEADERS = { "Content-Type", "Authorization", "X-Requested-With" };
    private static final String[] EXPOSED_HEADERS = { "Authorization" };
    private static final long MAX_AGE = 3600;

    /**
     * Configura CORS para permitir solicitudes desde el frontend admin desplegado en Vercel.
     * 
     * @return WebMvcConfigurer con la configuración de CORS personalizada.
     */
    @Bean
    public WebMvcConfigurer corsConfigurer() {
        return new WebMvcConfigurer() {
            @Override
            public void addCorsMappings(CorsRegistry registry) {
                registry.addMapping("/**")
                        .allowedOrigins(ALLOWED_ORIGINS)
                        .allowedMethods(ALLOWED_METHODS)
                        .allowedHeaders(ALLOWED_HEADERS)
                        .exposedHeaders(EXPOSED_HEADERS)
                        .allowCredentials(true)
                        .maxAge(MAX_AGE);
            }
        };
    }
}