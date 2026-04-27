window.addEventListener("DOMContentLoaded", async (event) => {
  // Toggle the side navigation
  const sidebarToggle = document.body.querySelector("#sidebarToggle");
  if (sidebarToggle) {
    // Uncomment Below to persist sidebar toggle between refreshes
    // if (localStorage.getItem('sb|sidebar-toggle') === 'true') {
    //     document.body.classList.toggle('sb-sidenav-toggled');
    // }
    sidebarToggle.addEventListener("click", (event) => {
      event.preventDefault();
      document.body.classList.toggle("sb-sidenav-toggled");
      localStorage.setItem(
        "sb|sidebar-toggle",
        document.body.classList.contains("sb-sidenav-toggled"),
      );
    });
  }
});

function mostrarAlerta(tipo, mensaje) {
  const Toast = Swal.mixin({
    toast: true,
    position: "top-end",
    iconColor: "white",
    customClass: {
      popup: "colored-toast",
    },
    showConfirmButton: false,
    timer: 2000,
    timerProgressBar: true,
  });

  Toast.fire({
    icon: tipo,
    title: mensaje,
  });
}

// Validación Bootstrap para formularios
(() => {
  "use strict";
  const forms = document.querySelectorAll(".needs-validation");
  Array.from(forms).forEach((form) => {
    form.addEventListener(
      "submit",
      (event) => {
        if (!form.checkValidity()) {
          event.preventDefault();
          event.stopPropagation();
        }
        form.classList.add("was-validated");
      },
      false,
    );
  });
})();

function obtenerNombreUsuario() {
  return localStorage.getItem("nombreUsuario");
}

async function cerrarSesion() {
  const URL = "https://eventvsmerida.onrender.com/api/auth/logout";

  try {
    const respuesta = await fetch(URL, {
      method: "POST",
      credentials: "include",
      headers: {
        "Content-Type": "application/json; charset=UTF-8",
      },
    });

    if (respuesta.ok) {
      sessionStorage.clear();
      localStorage.removeItem("nombreUsuario");
      window.location.href = `${window.location.origin}/html/login.html`;
    } else {
      console.warn('Logout falló, status:', respuesta.status);
    }
  } catch (error) {
    console.error("Error en scripts.js", error);
  }
}

async function logeado() {
  const URL = "https://eventvsmerida.onrender.com/api/auth/session";

  try {
    const respuesta = await fetch(URL, {
      method: "GET",
      credentials: "include",
      cache: "no-store",
    });

    return respuesta.status;
  } catch (error) {
    console.error("Error en scripts.js", error);
    return 500;
  }
}
