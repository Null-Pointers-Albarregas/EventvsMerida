window.addEventListener("DOMContentLoaded", async () => {
  const sesion = await logeado();

  if (sesion === 401) {
    window.location.href = `${window.location.origin}/html/login.html`;
    return;
  } else if (sesion === 200) {
    document.body.classList.remove("auth-pending");
  }

  const URL_BASE = "https://eventvsmerida.onrender.com/api/";

  await cargarUsuarios(URL_BASE);

  const form = document.getElementById("formAgregarUsuario");
  if (form) {
    form.addEventListener(
      "submit",
      function (event) {
        event.preventDefault();

        const contrasenia = document.getElementById("contrasena").value;
        const confirmarContrasenia = document.getElementById("confirmarContrasena").value;

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
          const formData = new FormData();
          formData.append("usuario", JSON.stringify(usuario));
          const fotoFile = document.getElementById("fotoUsuario").files[0];
          if (fotoFile) {
            formData.append("foto", fotoFile);
          }
          crearUsuario(URL_BASE, formData);
        }

        form.classList.add("was-validated");
      },
      false,
    );
  }

  const formEditar = document.getElementById("formEditarUsuario");
  let contrasenia = "";
  let nombreUsuario = "";

  formEditar.addEventListener(
    "submit",
    function (event) {
      if (!formEditar.checkValidity()) {
        event.preventDefault();
        event.stopPropagation();
        formEditar.classList.add("was-validated");
      } else {
        event.preventDefault();
        const usuario = {
          nombre: document.getElementById("nombreEditar").value,
          apellidos: document.getElementById("apellidosEditar").value,
          fechaNacimiento: formatearFecha(
            document.getElementById("fechaNacimientoEditar").value,
          ),
          email: document.getElementById("correoEditar").value,
          telefono: document.getElementById("telefonoEditar").value,
          password: contraseniaModificada ? contrasenia : null,
          idRol: 1,
        };
        const formData = new FormData();
        formData.append("usuario", JSON.stringify(usuario));
        const fotoFile = document.getElementById("formFileEditar")?.files?.[0];
        if (fotoFile) {
          formData.append("foto", fotoFile);
        }
        editarUsuario(URL_BASE, formEditar.dataset.id, formData);
      }
      formEditar.classList.add("was-validated");
    },
    false,
  );

  let contraseniaModificada = false;

  const formEditarContrasenia = document.getElementById(
    "formEditarContrasenia",
  );

  formEditarContrasenia.addEventListener(
    "submit",
    function (event) {
      const contraseniaEditar =
        document.getElementById("contraseniaEditar").value;
      const confirmarContraseniaEditar = document.getElementById(
        "confirmarContraseniaEditar",
      ).value;

      if (!formEditarContrasenia.checkValidity()) {
        event.preventDefault();
        event.stopPropagation();
        formEditarContrasenia.classList.add("was-validated");
      } else if (contraseniaEditar !== confirmarContraseniaEditar) {
        event.stopPropagation();
        event.preventDefault();
        mostrarAlerta("error", "Las contraseñas tienen que ser iguales");
      } else {
        event.preventDefault();
        contrasenia = document.getElementById("contraseniaEditar").value;

        bootstrap.Modal.getInstance(
          document.getElementById("modalEditarContrasenia"),
        ).hide();

        mostrarAlerta("info", "Contraseña actualizada pendiente de guardar");

        const modalEditarContrasenia = document.getElementById(
          "modalEditarContrasenia",
        );

        modalEditarContrasenia.addEventListener("hidden.bs.modal", function () {
          const modalEditarUsuario = new bootstrap.Modal(
            document.getElementById("modalEditarUsuario"),
          );
          modalEditarUsuario.show();
        });
      }
      formEditarContrasenia.classList.add("was-validated");
    },
    false,
  );

  // Limpia validaciones y campos al cerrar el modal de usuario
  const modalUsuario = document.getElementById("modalCrearUsuario");
  if (modalUsuario) {
    modalUsuario.addEventListener("hidden.bs.modal", function () {
      const form = document.getElementById("formAgregarUsuario");
      if (form) {
        form.classList.remove("was-validated");
        form.reset();
        document.getElementById("fotoUsuario").value = "";
      }
    });
  }

  const modalEditarUsuario = document.getElementById("modalEditarUsuario");
  if (modalEditarUsuario) {
    modalEditarUsuario.addEventListener("hidden.bs.modal", function () {
      const form = document.getElementById("formEditarUsuario");
      if (form) {
        form.classList.remove("was-validated");
        contraseniaModificada = false;
      }
    });
  }
});

async function cargarUsuarios(URL_BASE) {
  const tabla =
    document.getElementById("listadoUsuarios") ||
    document.getElementById("listadUsuarios");
  const loader = document.getElementById("loader");
  const body = document.querySelector("body");

  try {
    loader.style.display = "flex";
    body.classList.add("loading");

    const resp = await fetch(URL_BASE + "usuarios/registered", {
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
      document.getElementById("roles-vacio");

    if (!tabla) {
      console.error("No se encontró la tabla de usuarios (#listadoUsuarios)");
      return;
    }

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

    data.forEach((usuario) => {
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
      textoId.textContent = usuario.id;
      textoNombre.textContent = usuario.nombre;
      textoApellidos.textContent = usuario.apellidos;
      textofechaNac.textContent = formatearFecha(usuario.fechaNacimiento);
      textoCorreo.textContent = usuario.email;
      textoTelefono.textContent = usuario.telefono;
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

      // Botón ver
      const btnVer = document.createElement("button");
      btnVer.className = "btn btn-sm btn-primary";
      btnVer.innerHTML = '<i class="fa-solid fa-eye"></i>';
      btnVer.setAttribute("data-bs-toggle", "modal");
      btnVer.setAttribute("data-bs-target", "#modalVerUsuario");
      btnVer.addEventListener("click", async function () {
        const detalle = await obtenerUsuarioPorId(URL_BASE, usuario.id);
        if (detalle) {
          verUsuario(detalle);
        }
      });

      // Botón editar
      const btnEditar = document.createElement("button");
      btnEditar.className = "btn btn-sm btn-warning";
      btnEditar.innerHTML = '<i class="fa-solid fa-pen"></i>';
      btnEditar.setAttribute("data-id", usuario.id);
      btnEditar.setAttribute("data-nombre", usuario.nombre);
      btnEditar.setAttribute("data-bs-toggle", "modal");
      btnEditar.setAttribute("data-bs-target", "#modalEditarUsuario");
      btnEditar.addEventListener("click", async function () {
        const detalle = await obtenerUsuarioPorId(URL_BASE, usuario.id);
        const data = detalle || usuario;
        document.getElementById("formEditarUsuario").dataset.id = data.id;
        document.getElementById("nombreEditar").value = data.nombre;
        document.getElementById("apellidosEditar").value = data.apellidos;
        document.getElementById("fechaNacimientoEditar").value =
          data.fechaNacimiento;
        document.getElementById("correoEditar").value = data.email;
        document.getElementById("telefonoEditar").value = data.telefono;
        document.getElementById("nombreUsuario").innerText = data.nombre;
        const imagenUsuario = document.getElementById("imagenUsuario");
        const sinFotoUsuario = document.getElementById("sinFotoUsuario");
        if (data.fotoUrl) {
          imagenUsuario.src = data.fotoUrl;
          imagenUsuario.style.display = "block";
          sinFotoUsuario.style.display = "none";
        } else {
          imagenUsuario.style.display = "none";
          sinFotoUsuario.style.display = "block";
        }
      });

      // Botón eliminar
      const btnEliminar = document.createElement("button");
      btnEliminar.className = "btn btn-sm btn-danger";
      btnEliminar.innerHTML = '<i class="fa-solid fa-trash"></i>';
      btnEliminar.setAttribute("data-id", usuario.id);
      btnEliminar.setAttribute("data-nombre", usuario.nombre);
      btnEliminar.addEventListener("click", function () {
        eliminarUsuario(URL_BASE, this.dataset.id, this.dataset.nombre);
      });

      divGrupo.appendChild(btnVer);
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
      body.classList.remove("loading");
    }
  }
}

async function crearUsuario(URL_BASE, datosFormulario) {
  try {
    const options = {
      method: "POST",
      credentials: "include",
      body: datosFormulario,
    };
    const resp = await fetch(URL_BASE + "usuarios/add", options);
    const respuesta = await resp.json();
    if (resp.status === 201) {
      mostrarAlerta("success", "Usuario creado correctamente");

      const modal = bootstrap.Modal.getInstance(
        document.getElementById("modalCrearUsuario"),
      );
      modal.hide();
    } else {
      mostrarAlerta("error", "Error al crear el usuario: " + respuesta.error);
    }
  } catch (error) {
    console.error("Error al crear el usuario:", error);
  } finally {
    cargarUsuarios(URL_BASE);
  }
}

async function editarUsuario(URL_BASE, id, datosFormulario) {
  try {
    const options = {
      method: "PUT",
      credentials: "include",
      body: datosFormulario,
    };
    const resp = await fetch(URL_BASE + "usuarios/update/" + id, options);
    const respuesta = await resp.json();
    if (resp.status === 200) {
      mostrarAlerta("success", "Usuario editado correctamente");

      const modal = bootstrap.Modal.getInstance(
        document.getElementById("modalEditarUsuario"),
      );
      modal.hide();
    } else {
      mostrarAlerta("error", "Error al editar el usuario: " + respuesta.error);
    }
  } catch (error) {
    console.error("Error al editar el usuario:", error);
  } finally {
    cargarUsuarios(URL_BASE);
  }
}

async function eliminarUsuario(URL_BASE, id, nombre) {
  Swal.fire({
    title: `¿Estás seguro que deseas eliminar el usuario \"` + nombre + `\"?`,
    text: "Esta acción no puede revertirse",
    icon: "warning",
    showCancelButton: true,
    cancelButtonColor: "#3085d6",
    cancelButtonText: "Cancelar",
    confirmButtonColor: "#d33",
    confirmButtonText: "Eliminar usuario",
  }).then(async (result) => {
    if (result.isConfirmed) {
      try {
        const options = {
          method: "DELETE",
        };
        const resp = await fetch(URL_BASE + "usuarios/delete/" + id, options);
        if (resp.status === 204) {
          mostrarAlerta("success", "Usuario eliminado correctamente");
        } else {
          mostrarAlerta(
            "error",
            "Error al eliminar el usuario: " + respuesta.error,
          );
        }
      } catch (error) {
        console.error("Error al eliminar el usuario:", error);
      } finally {
        cargarUsuarios(URL_BASE);
      }
    }
  });
}

function verUsuario(usuario) {
  let contenido = `
    <h4 class="text-center">${usuario.nombre} ${usuario.apellidos}<br></h4>
  `;
  
  if (usuario.fotoUrl) {
    contenido += `<img src="${usuario.fotoUrl}" alt="${usuario.nombre}" class="img-fluid img-thumbnail img-usuario-modal mt-3 mb-2"><br>`;
  } else {
    contenido += `<div class="text-center text-muted mb-3">No hay foto de perfil</div>`;
  }
  
  contenido += `
    <p class="mb-1"><strong>Nombre:</strong> ${usuario.nombre}</p>
    <p class="mb-1"><strong>Apellidos:</strong> ${usuario.apellidos}</p>
    <p class="mb-1"><strong>Email:</strong> ${usuario.email}</p>
    <p class="mb-1"><strong>Teléfono:</strong> ${usuario.telefono}</p>
    <p class="mb-1"><strong>Fecha de nacimiento:</strong> ${formatearFecha(usuario.fechaNacimiento)}</p>
  `;
  
  document.getElementById("contenidoModalUsuario").innerHTML = contenido;
}

function formatearFecha(fechaISO) {
  const fecha = new Date(fechaISO);
  const dia = fecha.getDate().toString().padStart(2, "0");
  const mes = (fecha.getMonth() + 1).toString().padStart(2, "0");
  const anio = fecha.getFullYear();
  return `${dia}/${mes}/${anio}`;
}

async function obtenerUsuarioPorId(URL_BASE, id) {
  try {
    const resp = await fetch(URL_BASE + "usuarios/" + id, {
      method: "GET",
      credentials: "include",
      headers: {
        "Content-Type": "application/json",
      },
    });

    if (!resp.ok) {
      throw new Error("No se pudo obtener el usuario");
    }

    return await resp.json();
  } catch (error) {
    console.error("Error al obtener el usuario:", error);
    mostrarAlerta("error", "No se pudo cargar el usuario");
    return null;
  }
}