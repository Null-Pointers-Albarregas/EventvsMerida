package es.nullpointers.eventvsmerida.security;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class CorsConfig {
    private static final String[] ALLOWED_ORIGINS = {
            "https://eventvsmerida.onrender.com",
            "http://localhost:5501",
            //"https://eventvsmerida-admin.vercel.app"
    };
    private static final String[] ALLOWED_METHODS = { "GET", "POST", "PUT", "DELETE", "OPTIONS" };
    private static final String[] ALLOWED_HEADERS = { "Content-Type", "Authorization", "X-Requested-With" };
    private static final String[] EXPOSED_HEADERS = { "Authorization" };
    private static final long MAX_AGE = 3600;

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
                        .maxAge(MAX_AGE);
            }
        };
    }
}