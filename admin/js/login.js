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
    URL = "https://eventvsmerida.onrender.com/api/usuarios/login";

    try {
        const respuesta = await fetch(URL, {
            method: "POST",
            body: JSON.stringify(datos),
            headers: {
                "Content-Type": "application/json; charset=UTF-8",
            },
        });

        if (respuesta.status >= 200 && respuesta.status < 300) {
            const nombreUsuario = datos["email"].split("@")[0];
            localStorage.setItem("nombreUsuario", nombreUsuario)
            window.location.href = "../index.html"
        } else if (respuesta.status === 400 || respuesta.status === 401 || respuesta.status === 404){
            mostrarAlerta("error", "Usuario o contraseña incorrectos")
        } 
        else {
            const errorTexto = await respuesta.text();
            throw new Error(`Error ${respuesta.status}: ${errorTexto}`);
        }
    } catch (error) {
        if (error.name === "TypeError") {
            return { éxito: false, mensaje: "Problema de red o CORS" };
        }
        return { éxito: false, mensaje: error.message };
    }
}