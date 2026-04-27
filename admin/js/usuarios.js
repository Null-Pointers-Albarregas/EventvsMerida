window.addEventListener("DOMContentLoaded", async (event) => {
  const URL_BASE = "https://eventvsmerida.onrender.com/api/";

  obtenerRoles(URL_BASE);
});

async function obtenerUsuarios(URL_BASE) {
  try {
    const resp = await fetch(URL_BASE + "usuarios/all", {
      method: "GET",
      headers: {
        "Content-Type": "application/json",
      },
      credentials: "include"
    });

    if (!resp.ok) {
      throw new Error("Error al obtener los usuarios");
    }

    const tabla = document.getElementById("listadoUsuarios");

    const data = await resp.json();
    data.forEach((rol) => {
      const opt = document.createElement("option");
      
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
}

async function obtenerRoles(URL_BASE) {
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

    const select = document.getElementById("roles");

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
}
