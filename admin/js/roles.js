window.addEventListener("DOMContentLoaded", async (event) => {
  const URL_BASE = "https://eventvsmerida.onrender.com/api/";
  cargarCategorias(URL_BASE);

  const form = document.getElementById("formAgregarRol");

  form.addEventListener(
    "submit",
    function (event) {
      if (!form.checkValidity()) {
        event.preventDefault();
        event.stopPropagation();
        form.classList.add("was-validated");
      } else {
        event.preventDefault();
        const rol = {
          nombre: document.getElementById("nombreRol").value,
        };
        subirCategoria(URL_BASE, rol);
      }
      form.classList.add("was-validated");
    },
    false,
  );
});

async function cargarCategorias(URL_BASE) {
  const tabla = document.getElementById("listadoRoles");
  const loader = document.getElementById("loader");

  try {
    loader.style.display = "flex";

    const resp = await fetch(URL_BASE + "roles/all", {
      method: "GET",
      headers: {
        "Content-Type": "application/json",
      },
    });

    const data = await resp.json();

    // Mostrar mensaje si no hay categorías y limpiar tabla
    const rolesVacio = document.getElementById("roles-vacio");
    if (data.length === 0) {
      rolesVacio.classList.remove("d-none");
      rolesVacio.classList.add("d-block");
      tabla.innerHTML = "";
      return;
    } else {
      rolesVacio.classList.remove("d-block");
      rolesVacio.classList.add("d-none");
    }

    data.forEach((rol) => {
      const tr = document.createElement("tr");
      const tdRoles = document.createElement("td");
      const textoRoles = document.createElement("div");
      textoRoles.textContent = rol["nombre"];
      tdRoles.appendChild(textoRoles);
      tdRoles.classList.add("text-light");
      tr.appendChild(tdRoles);
      const tdAcciones = document.createElement("td");
      const divGrupo = document.createElement("div");
      divGrupo.className = "btn-group";
      divGrupo.setAttribute("role", "group");

      // // Botón editar
      const btnEditar = document.createElement("button");
      btnEditar.className = "btn btn-sm btn-warning";
      btnEditar.innerHTML = '<i class="fa-solid fa-pen"></i>';
      btnEditar.setAttribute("data-id", rol.id);
      btnEditar.setAttribute("data-bs-toggle", "modal");
      btnEditar.setAttribute("data-bs-target", "#modalEditarRol");
      btnEditar.addEventListener("click", function () {
        document.getElementById("nombreRolEditar").value = rol.nombre;
      });

      // Botón eliminar
      const btnEliminar = document.createElement("button");
      btnEliminar.className = "btn btn-sm btn-danger";
      btnEliminar.innerHTML = '<i class="fa-solid fa-trash"></i>';
      btnEliminar.setAttribute("data-id", rol.nombre);
      btnEliminar.addEventListener("click", function () {
        //eliminarEvento();
      });

      divGrupo.appendChild(btnEditar);
      divGrupo.appendChild(btnEliminar);

      tdAcciones.appendChild(divGrupo);
      tdAcciones.classList.add("text-end");
      tr.appendChild(tdAcciones);
      tabla.appendChild(tr);
    });
  } catch (error) {
    console.error("Error al cargar los roles:", error);
  } finally {
    loader.style.display = "none";
  }
}

async function subirCategoria(URL_BASE, datosCategoria) {
  try {
    const options = {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(datosCategoria),
    };
    const resp = await fetch(URL_BASE + "roles/add", options);
    const respuesta = await resp.json();
    if (resp.status === 201) {
      mostrarAlerta("success", "Rol creado correctamente");
    } else {
      mostrarAlerta("error", "Error al crear el rol: " + respuesta.error);
    }
  } catch (error) {
    console.error("Error al subir el rol:", error);
  }
}
