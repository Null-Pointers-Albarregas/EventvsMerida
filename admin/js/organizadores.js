window.addEventListener("DOMContentLoaded", async () => {
  const sesion = await logeado();

  if (sesion === 401) {
    window.location.href = `${window.location.origin}/html/login.html`;
    return;
  } else if (sesion === 200) {
    document.body.classList.remove("auth-pending");
  }

  const URL_BASE = "https://eventvsmerida.onrender.com/api/";
  cargarOrganizadores(URL_BASE);

  const form = document.getElementById("formAgregarOrganizador");
  if (form) {
    form.addEventListener(
      "submit",
      function (event) {
        event.preventDefault();

        const contrasenia = document.getElementById("contrasena").value;
        const confirmarContrasenia = document.getElementById(
          "confirmarContrasena",
        ).value;

        if (!form.checkValidity()) {
          event.stopPropagation();
        } else if (contrasenia !== confirmarContrasenia) {
          event.stopPropagation();
          mostrarAlerta("error", "Las contraseñas tienen que ser iguales");
        } else {
          const usuario = {
            nombre: document.getElementById("nombre").value,
            apellidos: document.getElementById("apellidos").value,
            fechaNacimiento: formatearFecha(
              document.getElementById("fechaNacimiento").value,
            ),
            email: document.getElementById("correo").value,
            telefono: document.getElementById("telefono").value,
            password: contrasenia,
            idRol: 1,
          };
          subirUsuario(URL_BASE, usuario);
        }

        form.classList.add("was-validated");
      },
      false,
    );
  }

  const formEditar = document.getElementById("formEditarOrganizador");

  formEditar.addEventListener(
    "submit",
    function (event) {
      if (!formEditar.checkValidity()) {
        event.preventDefault();
        event.stopPropagation();
        formEditar.classList.add("was-validated");
      } else {
        event.preventDefault();
        const organizador = {
          nombre: document.getElementById("nombre").value,
          apellidos: document.getElementById("apellidos").value,
          fechaNacimiento: formatearFecha(
            document.getElementById("fechaNacimiento").value,
          ),
          email: document.getElementById("correo").value,
          telefono: document.getElementById("telefono").value,
          password: contrasenia,
          idRol: 1,
        };
        editarRol(URL_BASE, formEditar.dataset.id, rol);
      }
      formEditar.classList.add("was-validated");
    },
    false,
  );

  // Limpia validaciones y campos al cerrar el modal de usuario
  const modalOrganizador = document.getElementById("modalAgregarOrganizador");
  if (modalOrganizador) {
    modalOrganizador.addEventListener("hidden.bs.modal", function () {
      const form = document.getElementById("formAgregarOrganizador");
      if (form) {
        form.classList.remove("was-validated");
        form.reset();
      }
    });
  }

  const modalEditarOrganizador = document.getElementById("modalEditarOrganizador");
  if (modalEditarOrganizador) {
    modalEditarUsuario.addEventListener("hidden.bs.modal", function () {
      const form = document.getElementById("formEditarOrganizador");
      if (form) {
        form.classList.remove("was-validated");
        form.reset();
      }
    });
  }
});

async function cargarOrganizadores(URL_BASE) {
  const tabla = document.getElementById("listadoOrganizadores");
  const loader = document.getElementById("loader");

  try {
    if (loader) {
      loader.style.display = "flex";
    }

    const resp = await fetch(URL_BASE + "usuarios/organizers", {
      method: "GET",
      credentials: "include",
      headers: {
        "Content-Type": "application/json",
      },
    });

    const data = await resp.json();

    // Mostrar mensaje si no hay usuarios y limpiar tabla
    const usuariosVacio =
      document.getElementById("usuarios-vacio") ||
      document.getElementById("organizadores-vacio");

    if (data.length === 0) {
      if (usuariosVacio) {
        usuariosVacio.classList.remove("d-none");
        usuariosVacio.classList.add("d-block");
      }
      tabla.innerHTML = "";
      return;
    } else {
      if (usuariosVacio) {
        usuariosVacio.classList.remove("d-block");
        usuariosVacio.classList.add("d-none");
      }
    }

    tabla.innerHTML = "";

    data.forEach((organizador) => {
      const tr = document.createElement("tr");
      const tdId = document.createElement("td");
      const textoId = document.createElement("div");
      const tdNombre = document.createElement("td");
      const textoNombre = document.createElement("div");
      const tdApellidos = document.createElement("td");
      const textoApellidos = document.createElement("div");
      const tdfechaNac = document.createElement("td");
      const textofechaNac = document.createElement("div");
      const tdCorreo = document.createElement("td");
      const textoCorreo = document.createElement("div");
      const tdTelefono = document.createElement("td");
      const textoTelefono = document.createElement("div");
      textoId.textContent = organizador.id;
      textoNombre.textContent = organizador.nombre;
      textoApellidos.textContent = organizador.apellidos;
      textofechaNac.textContent = formatearFecha(organizador.fechaNacimiento);
      textoCorreo.textContent = organizador.email;
      textoTelefono.textContent = organizador.telefono;
      tdId.appendChild(textoId);
      tdNombre.appendChild(textoNombre);
      tdApellidos.appendChild(textoApellidos);
      tdfechaNac.appendChild(textofechaNac);
      tdCorreo.appendChild(textoCorreo);
      tdTelefono.appendChild(textoTelefono);
      tr.appendChild(tdId);
      tr.appendChild(tdNombre);
      tr.appendChild(tdApellidos);
      tr.appendChild(tdfechaNac);
      tr.appendChild(tdCorreo);
      tr.appendChild(tdTelefono);
      const tdAcciones = document.createElement("td");
      const divGrupo = document.createElement("div");
      divGrupo.className = "btn-group";
      divGrupo.setAttribute("role", "group");

      // Botón editar
      const btnEditar = document.createElement("button");
      btnEditar.className = "btn btn-sm btn-warning";
      btnEditar.innerHTML = '<i class="fa-solid fa-pen"></i>';
      btnEditar.setAttribute("data-id", organizador.id);
      btnEditar.setAttribute("data-bs-toggle", "modal");
      btnEditar.setAttribute("data-bs-target", "#modalEditarOrganizador");
      btnEditar.addEventListener("click", function () {
        document.getElementById("formEditarOrganizador").dataset.id =
          organizador.id;
        document.getElementById("nombreEditar").value = organizador.nombre;
        document.getElementById("apellidosEditar").value =
          organizador.apellidos;
        document.getElementById("fechaNacimientoEditar").value =
          organizador.fechaNacimiento;
        document.getElementById("correoEditar").value = organizador.email;
        document.getElementById("telefonoEditar").value = organizador.telefono;
      });

      // Botón eliminar
      const btnEliminar = document.createElement("button");
      btnEliminar.className = "btn btn-sm btn-danger";
      btnEliminar.innerHTML = '<i class="fa-solid fa-trash"></i>';
      btnEliminar.setAttribute("data-id", organizador.id);
      btnEliminar.setAttribute("data-nombre", organizador.nombre);
      btnEliminar.addEventListener("click", function () {
        eliminarOrganizador(URL_BASE, this.dataset.id, this.dataset.nombre);
      });

      divGrupo.appendChild(btnEditar);
      divGrupo.appendChild(btnEliminar);

      tdAcciones.appendChild(divGrupo);
      tdAcciones.classList.add("text-end");
      tr.appendChild(tdAcciones);
      tabla.appendChild(tr);
    });
  } catch (error) {
    console.error("Error al cargar los usuarios:", error);
  } finally {
    if (loader) {
      loader.style.display = "none";
    }
  }
}

async function subirOrganizador(URL_BASE, datosFormulario) {
  try {
    const options = {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      credentials: "include",
      body: JSON.stringify(datosFormulario),
    };
    const resp = await fetch(URL_BASE + "usuarios/add", options);
    const respuesta = await resp.json();
    if (resp.status === 201) {
      mostrarAlerta("success", "Usuario creado correctamente");
    } else {
      mostrarAlerta("error", "Error al crear el usuario: " + respuesta.error);
    }
  } catch (error) {
    console.error("Error al subir el evento:", error);
  } finally {
    cargarOrganizadores(URL_BASE);
  }
}

async function eliminarOrganizador(URL_BASE, id, nombre) {
  Swal.fire({
    title: `¿Estás seguro que deseas eliminar el organizador \"` + nombre + `\"?`,
    text: "Esta acción no puede revertirse",
    icon: "warning",
    showCancelButton: true,
    cancelButtonColor: "#3085d6",
    cancelButtonText: "Cancelar",
    confirmButtonColor: "#d33",
    confirmButtonText: "Eliminar organizador",
  }).then(async (result) => {
    if (result.isConfirmed) {
      try {
        const options = {
          method: "DELETE",
        };
        const resp = await fetch(URL_BASE + "usuarios/delete/" + id, options);
        if (resp.status === 204) {
          mostrarAlerta("success", "Organizador eliminado correctamente");
        } else {
          mostrarAlerta(
            "error",
            "Error al eliminar el organizador: " + respuesta.error,
          );
        }
      } catch (error) {
        console.error("Error al eliminar el organizador:", error);
      } finally {
        cargarOrganizadores(URL_BASE);
      }
    }
  });
}

function formatearFecha(fechaISO) {
  const fecha = new Date(fechaISO);
  const dia = fecha.getDate().toString().padStart(2, "0");
  const mes = (fecha.getMonth() + 1).toString().padStart(2, "0");
  const anio = fecha.getFullYear();
  return `${dia}/${mes}/${anio}`;
}
