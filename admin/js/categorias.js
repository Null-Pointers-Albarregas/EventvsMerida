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

      // // Botón editar
      const btnEditar = document.createElement("button");
      btnEditar.className = "btn btn-sm btn-warning";
      btnEditar.innerHTML = '<i class="fa-solid fa-pen"></i>';
      btnEditar.setAttribute("data-id", categoria.id);
      btnEditar.setAttribute("data-bs-toggle", "modal");
      btnEditar.setAttribute("data-bs-target", "#modalEditarCategoria");
      btnEditar.addEventListener("click", function () {
        document.getElementById("nombreCategoriaEditar").value =
          categoria.nombre;
      });

      // Botón eliminar
      const btnEliminar = document.createElement("button");
      btnEliminar.className = "btn btn-sm btn-danger";
      btnEliminar.innerHTML = '<i class="fa-solid fa-trash"></i>';
      btnEliminar.setAttribute("data-id", categoria.nombre);
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
    } else {
      mostrarAlerta("error", "Error al crear la categoría: " + respuesta.error);
    }
  } catch (error) {
    console.error("Error al subir la categoría:", error);
  }
}
