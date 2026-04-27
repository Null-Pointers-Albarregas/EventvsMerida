window.addEventListener("DOMContentLoaded", async () => {
  const sesion = await logeado();

  if (sesion === 401) {
    window.location.href = `${window.location.origin}/html/login.html`;
    return;
  } else if (sesion === 200){
    document.body.classList.remove("auth-pending");
  }

  const URL_BASE = "https://eventvsmerida.onrender.com/api/";
  cargarRoles(URL_BASE);

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
        subirRol(URL_BASE, rol);
      }
      form.classList.add("was-validated");
    },
    false,
  );

  const formEditar = document.getElementById("formEditarRol");

  formEditar.addEventListener(
    "submit",
    function (event) {
      if (!formEditar.checkValidity()) {
        event.preventDefault();
        event.stopPropagation();
        formEditar.classList.add("was-validated");
      } else {
        event.preventDefault();
        const rol = {
          nombre: document.getElementById("nombreRolEditar").value,
        };
        editarRol(URL_BASE, formEditar.dataset.id, rol);
      }
      formEditar.classList.add("was-validated");
    },
    false,
  );
});

async function cargarRoles(URL_BASE) {
  const tabla = document.getElementById("listadoRoles");
  const loader = document.getElementById("loader");

  try {
    loader.style.display = "flex";

    const resp = await fetch(URL_BASE + "roles/all", {
      method: "GET",
      headers: {
        "Content-Type": "application/json",
      },
      credentials: "include",
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
      const tdId = document.createElement("td");
      const textoId = document.createElement("div");
      const tdRoles = document.createElement("td");
      const textoRoles = document.createElement("div");
      textoId.textContent = rol.id;
      textoRoles.textContent = rol.nombre;
      tdId.appendChild(textoId);
      tdRoles.appendChild(textoRoles);
      tdRoles.classList.add("text-light");
      tr.appendChild(tdId);
      tr.appendChild(tdRoles);
      const tdAcciones = document.createElement("td");
      const divGrupo = document.createElement("div");
      divGrupo.className = "btn-group";
      divGrupo.setAttribute("role", "group");

      // Botón editar
      const btnEditar = document.createElement("button");
      btnEditar.className = "btn btn-sm btn-warning";
      btnEditar.innerHTML = '<i class="fa-solid fa-pen"></i>';
      btnEditar.setAttribute("data-id", rol.id);
      btnEditar.setAttribute("data-bs-toggle", "modal");
      btnEditar.setAttribute("data-bs-target", "#modalEditarRol");
      btnEditar.addEventListener("click", function () {
        document.getElementById("formEditarRol").dataset.id =
          rol.id;
        document.getElementById("nombreRolEditar").value =
          rol.nombre;
        document.getElementById("nombreRolEditar").value = rol.nombre;
      });

      // Botón eliminar
      const btnEliminar = document.createElement("button");
      btnEliminar.className = "btn btn-sm btn-danger";
      btnEliminar.innerHTML = '<i class="fa-solid fa-trash"></i>';
      btnEliminar.setAttribute("data-id", rol.id);
      btnEliminar.setAttribute("data-nombre", rol.nombre);
      btnEliminar.addEventListener("click", function () {
        eliminarRol(URL_BASE, this.dataset.id, this.dataset.nombre);
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

async function subirRol(URL_BASE, datosCategoria) {
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

      const modal = bootstrap.Modal.getInstance(
        document.getElementById("modalCrearRol"),
      );
      modal.hide();
    } else {
      mostrarAlerta("error", "Error al crear el rol: " + respuesta.error);
    }
  } catch (error) {
    console.error("Error al subir el rol:", error);
  }
}