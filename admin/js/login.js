window.addEventListener("DOMContentLoaded", async (event) => {
    const form = document.querySelector(".needs-validation");


    form.addEventListener("submit", function (event) {
        if (!form.checkValidity()) {
            event.preventDefault();
            event.stopPropagation();
        } else {
            event.preventDefault();
            const datosFormulario = {
                email: document.getElementById("correo").value,
                password: document.getElementById("contrasenia").value
            };
            login(datosFormulario);
        }
        form.classList.add("was-validated");
    }, false);
});

async function login(datos) {
    const URL = "https://eventvsmerida.onrender.com/api/auth/login?admin=true";

    try {
        const respuesta = await fetch(URL, {
            method: "POST",
            credentials: "include",
            body: JSON.stringify(datos),
            headers: {
                "Content-Type": "application/json",
            },
        });

        if (respuesta.status >= 200 && respuesta.status < 300) {
            const nombreUsuario = datos["email"].split("@")[0];
            //localStorage.setItem("nombreUsuario", nombreUsuario)
            window.location.href = "../index.html"
        } else if (respuesta.status === 400 || respuesta.status === 401 || respuesta.status === 403 || respuesta.status === 404 || respuesta.status === 500){
            mostrarAlerta("error", "Usuario o contraseña incorrectos")
        } else if (respuesta.status === 403) {
            mostrarAlerta("error", "No estás autorizado para acceder")
        }
        else {
            mostrarAlerta("error", "Ha ocurrido un problema inesperado")
            const errorTexto = await respuesta.text();
            console.error(`Error ${respuesta.status}: ${errorTexto}`);
        }
    } catch (error) {
        if (error.name === "TypeError") {
            return { éxito: false, mensaje: "Problema de red o CORS" };
        }
        return { éxito: false, mensaje: error.message };
    }
}
