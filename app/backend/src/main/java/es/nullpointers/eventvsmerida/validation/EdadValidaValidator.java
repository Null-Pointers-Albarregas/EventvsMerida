package es.nullpointers.eventvsmerida.validation;

import jakarta.validation.ConstraintValidator;
import jakarta.validation.ConstraintValidatorContext;
import java.time.LocalDate;
import java.time.Period;

public class EdadValidaValidator implements ConstraintValidator<EdadValida, LocalDate> {
    @Override
    public boolean isValid(LocalDate fechaNacimiento, ConstraintValidatorContext context) {
        if (fechaNacimiento == null) {
            return true;
        }

        int edad = Period.between(fechaNacimiento, LocalDate.now()).getYears();
        return edad >= 14 && edad <= 100;
    }
}