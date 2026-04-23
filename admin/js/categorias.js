window.addEventListener("DOMContentLoaded", async (event) => {
  const URL_BASE = "https://eventvsmerida.onrender.com/api/";
  cargarCategorias(URL_BASE);

  const form = document.getElementById("formAgregarCategoria");

  form.addEventListener(
    "submit",
    function (event) {
      if (!form.checkValidity()) {
        event.preventDefault();
        event.stopPropagation();
        form.classList.add("was-validated");
      } else {
        event.preventDefault();
        const categoria = {
          nombre: document.getElementById("nombreCategoria").value,
        };
        subirCategoria(URL_BASE, categoria);
      }
      form.classList.add("was-validated");
    },
    false,
  );

  const formEditar = document.getElementById("formEditarCategoria");

  formEditar.addEventListener(
    "submit",
    function (event) {
      if (!formEditar.checkValidity()) {
        event.preventDefault();
        event.stopPropagation();
        formEditar.classList.add("was-validated");
      } else {
        event.preventDefault();
        const categoria = {
          nombre: document.getElementById("nombreCategoriaEditar").value,
        };
        editarCategoria(URL_BASE, formEditar.dataset.id, categoria);
      }
      form.classList.add("was-validated");
    },
    false,
  );
});

async function cargarCategorias(URL_BASE) {
  const tabla = document.getElementById("listadoCategorias");
  const loader = document.getElementById("loader");

  try {
    loader.style.display = "flex";

    const resp = await fetch(URL_BASE + "categorias/all", {
      method: "GET",
      headers: {
        "Content-Type": "application/json",
      },
    });

    const data = await resp.json();

    // Mostrar mensaje si no hay categorías y limpiar tabla
    const categoriasVacia = document.getElementById("categorias-vacia");
    if (data.length === 0) {
      categoriasVacia.classList.remove("d-none");
      categoriasVacia.classList.add("d-block");
      tabla.innerHTML = "";
      return;
    } else {
      categoriasVacia.classList.remove("d-block");
      categoriasVacia.classList.add("d-none");
    }

    data.forEach((categoria) => {
      const tr = document.createElement("tr");
      const tdCategoria = document.createElement("td");
      const textoCategoria = document.createElement("div");
      textoCategoria.textContent = categoria["nombre"];
      tdCategoria.appendChild(textoCategoria);
      tdCategoria.classList.add("text-light");
      tr.appendChild(tdCategoria);
      const tdAcciones = document.createElement("td");
      const divGrupo = document.createElement("div");
      divGrupo.className = "btn-group";
      divGrupo.setAttribute("role", "group");

      // Botón editar
      const btnEditar = document.createElement("button");
      btnEditar.className = "btn btn-sm btn-warning";
      btnEditar.innerHTML = '<i class="fa-solid fa-pen"></i>';
      btnEditar.setAttribute("data-id", categoria.id);
      btnEditar.setAttribute("data-nombre", categoria.nombre);
      btnEditar.setAttribute("data-bs-toggle", "modal");
      btnEditar.setAttribute("data-bs-target", "#modalEditarCategoria");
      btnEditar.addEventListener("click", function () {
        document.getElementById("formEditarCategoria").dataset.id =
          categoria.id;
        document.getElementById("nombreCategoriaEditar").value =
          categoria.nombre;
      });

      // Botón eliminar
      const btnEliminar = document.createElement("button");
      btnEliminar.className = "btn btn-sm btn-danger";
      btnEliminar.innerHTML = '<i class="fa-solid fa-trash"></i>';
      btnEliminar.setAttribute("data-id", categoria.id);
      btnEliminar.setAttribute("data-nombre", categoria.nombre);
      btnEliminar.addEventListener("click", function () {
        eliminarCategoria(URL_BASE, this.dataset.id, this.dataset.nombre);
      });

      divGrupo.appendChild(btnEditar);
      divGrupo.appendChild(btnEliminar);

      tdAcciones.appendChild(divGrupo);
      tdAcciones.classList.add("text-end");
      tr.appendChild(tdAcciones);
      tabla.appendChild(tr);
    });
  } catch (error) {
    console.error("Error al cargar las categorías:", error);
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
    const resp = await fetch(URL_BASE + "categorias/add", options);
    const respuesta = await resp.json();
    if (resp.status === 201) {
      mostrarAlerta("success", "Categoría creada correctamente");

      const modal = bootstrap.Modal.getInstance(
        document.getElementById("modalEditarCategoria"),
      );
      modal.hide();
    } else {
      mostrarAlerta("error", "Error al crear la categoría: " + respuesta.error);
    }
  } catch (error) {
    console.error("Error al subir la categoría:", error);
  }
}

async function editarCategoria(URL_BASE, id, datosCategoria) {
  try {
    const options = {
      method: "PUT",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(datosCategoria),
    };
    const resp = await fetch(URL_BASE + "categorias/update/" + id, options);
    const respuesta = await resp.json();
    if (resp.status === 200) {
      mostrarAlerta("success", "Categoría editada correctamente");

      const modal = bootstrap.Modal.getInstance(
        document.getElementById("modalEditarCategoria"),
      );
      modal.hide();
    } else {
      mostrarAlerta(
        "error",
        "Error al editar la categoría: " + respuesta.error,
      );
    }
  } catch (error) {
    console.error("Error al editar la categoría:", error);
  } finally {
    cargarCategorias(URL_BASE);
  }
}

async function eliminarCategoria(URL_BASE, id, categoria) {
  Swal.fire({
    title: "¿Estás seguro que deseas eliminar la categoría \"" + categoria +"\"?",
    text: "Esta acción no puede revertirse",
    icon: "warning",
    showCancelButton: true,
    cancelButtonColor: "#3085d6",
    cancelButtonText: "Cancelar",
    confirmButtonColor: "#d33",
    confirmButtonText: "Eliminar categoría",
  }).then((result) => {
    if (result.isConfirmed) {
      try {
        const options = {
          method: "DELETE",
        };
        const resp = fetch(URL_BASE + "categorias/delete/" + id, options);
        if (resp.status === 204) {
          mostrarAlerta("success", "Evento eliminado correctamente");
        } else {
          mostrarAlerta(
            "error",
            "Error al eliminar la categoria: " + resp.error,
          );
        }
      } catch (error) {
        console.error("Error al eliminar el evento:", error);
      }
    }
  });
}