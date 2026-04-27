window.addEventListener("DOMContentLoaded", async () => {
  const sesion = await logeado();

  if (sesion === 401) {
    window.location.href = `${window.location.origin}/html/login.html`;
    return;
  } else if (sesion === 200){
    document.body.classList.remove("auth-pending");
  }
  
  const URL_BASE = "https://eventvsmerida.onrender.com/api/";

  const select = document.getElementById("roles");

  try {
    const resp = await fetch(URL_BASE + "roles/all", {
      method: "GET",
      headers: {
        "Content-Type": "application/json",
      },
    });

    if (!resp.ok) {
      throw new Error("Error al obtener los roles");
    }

    const data = await resp.json();
    data.forEach((rol) => {
      const opt = document.createElement("option");
      switch (rol["nombre"]) {
        case "Registrado":
          opt.value = 1;
          break;
        case "Organizador":
          opt.value = 2;
          break;
        case "Administrador":
          opt.value = 3;
          break;
        default:
          opt.value = 0;
      }
      opt.textContent = rol["nombre"];
      select.appendChild(opt);

      // Limpia validaciones y campos al cerrar el modal de usuario
      const modalUsuario = document.getElementById("modalCrearUsuario");
      if (modalUsuario) {
        modalUsuario.addEventListener("hidden.bs.modal", function () {
          const form = document.getElementById("formAgregarUsuario");
          if (form) {
            form.classList.remove("was-validated");
            form.reset();
          }
        });
      }

      modalUsuario.addEventListener("submit", async function (event) {
        event.preventDefault();
        const form = document.getElementById("formAgregarUsuario");
        if (form.checkValidity()) {
          mostrarAlerta("success", "Usuario creado correctamente");
        }
      });
    });
  } catch (error) {
    console.error("Error al cargar los roles:", error);
  }
});