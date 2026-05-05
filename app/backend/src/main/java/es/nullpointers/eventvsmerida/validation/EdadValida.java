package es.nullpointers.eventvsmerida.validation;

import jakarta.validation.Constraint;
import jakarta.validation.Payload;
import java.lang.annotation.*;

@Documented
@Constraint(validatedBy = EdadValidaValidator.class)
@Target({ ElementType.FIELD })
@Retention(RetentionPolicy.RUNTIME)
public @interface EdadValida {
    String message() default "La edad debe estar entre 14 y 100 años";
    Class<?>[] groups() default {};
    Class<? extends Payload>[] payload() default {};
}