const URL_BASE = "https://eventvsmerida.onrender.com/api/";

window.addEventListener("DOMContentLoaded", async () => {
  const sesion = await logeado();

  if (sesion === 401) {
    window.location.href = `${window.location.origin}/html/login.html`;
    return;
  } else if (sesion === 200) {
    document.body.classList.remove("auth-pending");
  }

  paginaActual = 0;
  cantidadPaginacion = 1;
  cargarEventos();
  //buscarEvento("mit");
  obtenerCategorias();

  // Buscador de eventos provisional
  document.addEventListener("keyup", (e) => {
    if (e.target.matches("#buscador")) {
      buscarEvento(e.target.value);
    }
  });

  const form = document.getElementById("formAgregarEvento");

  form.addEventListener(
    "submit",
    function (event) {
      if (!form.checkValidity()) {
        event.preventDefault();
        event.stopPropagation();
        form.classList.add("was-validated");
      } else {
        event.preventDefault();
        const evento = {
          titulo: document.getElementById("titulo").value,
          descripcion: document.getElementById("descripcion").value,
          fechaInicio:
            document.getElementById("fechaInicio").value +
            "T" +
            document.getElementById("horaInicio").value +
            ":00.000",
          fechaFin:
            document.getElementById("fechaFin").value +
            "T" +
            document.getElementById("horaFin").value +
            ":00.000",
          localizacion: document.getElementById("localizacion").value,
          idUsuario: 3,
          idCategoria: asociarIdCategoria(
            document.getElementById("categorias").value,
          ),
        };
        const formData = new FormData();
        formData.append("evento", JSON.stringify(evento));
        formData.append("foto", document.getElementById("fotoEvento").files[0]);
        subirEvento(formData, true);
      }
      form.classList.add("was-validated");
    },
    false,
  );

  const formEditar = document.getElementById("formEditarEvento");
  formEditar.addEventListener(
    "submit",
    function (event) {
      if (!formEditar.checkValidity()) {
        event.preventDefault();
        event.stopPropagation();
        formEditar.classList.add("was-validated");
      } else {
        event.preventDefault();
        const evento = {
          titulo: document.getElementById("titulo").value,
          descripcion: document.getElementById("descripcion").value,
          fechaInicio:
            document.getElementById("fechaInicio").value +
            "T" +
            document.getElementById("horaInicio").value +
            ":00.000",
          fechaFin:
            document.getElementById("fechaFin").value +
            "T" +
            document.getElementById("horaFin").value +
            ":00.000",
          localizacion: document.getElementById("localizacion").value,
          idUsuario: 3,
          idCategoria: asociarIdCategoria(
            document.getElementById("categorias").value,
          ),
        };
        const formData = new FormData();
        formData.append("evento", JSON.stringify(evento));
        formData.append("foto", document.getElementById("fotoEvento").files[0]);
        editarEvento(formEditar.dataset.id, formData);
      }
      formEditar.classList.add("was-validated");
    },
    false,
  );
});

async function cargarEventos() {
  const loader = document.getElementById("loader");
  const body = document.querySelector("body");

  try {
    loader.style.display = "flex";
    body.classList.add("loading");

    const resp = await fetch(
      URL_BASE + `eventos/paginated?page=${paginaActual}&size=10`,
      {
        method: "GET",
        headers: {
          "Content-Type": "application/json",
        },
      },
    );

    const data = await resp.json();
    mostrarEventos(data["content"]);
  } catch (error) {
    console.error("Error al cargar los eventos:", error);
  } finally {
    body.classList.remove("loading");
    loader.style.display = "none";
  }
}

async function buscarEvento(textoBusqueda) {
  const loader = document.getElementById("loader");
  const body = document.querySelector("body");

  try {
    loader.style.display = "flex";
    body.classList.add("loading");

    const resp = await fetch(
      URL_BASE + `eventos/search?q=${textoBusqueda}&limit=10`,
      {
        method: "GET",
        headers: {
          "Content-Type": "application/json",
        },
        credentials: "include",
      },
    );

    if (!resp.ok) {
      throw new Error("Error al obtener los categorías");
    }

    const data = await resp.json();
    mostrarEventos(data);
  } catch (error) {
    console.error("Error al buscar el evento", error);
  } finally {
    body.classList.remove("loading");
    loader.style.display = "none";
  }
}

function mostrarEventos(data) {
  const tabla = document.getElementById("listadoEventos");

  // Mostrar mensaje si no hay eventos y limpiar tabla
  const eventosVacio = document.getElementById("eventos-vacio");
  if (data.length === 0) {
    eventosVacio.classList.remove("d-none");
    eventosVacio.classList.add("d-block");
    tabla.innerHTML = "";
    return;
  } else {
    eventosVacio.classList.remove("d-block");
    eventosVacio.classList.add("d-none");
  }

  tabla.innerHTML = "";
  data.forEach((evento) => {
    const tr = document.createElement("tr");
    const tdId = document.createElement("td");
    const tdTitulo = document.createElement("td");
    const tdDescripcion = document.createElement("td");
    const tdFechaInicio = document.createElement("td");
    const tdFechaFin = document.createElement("td");
    const tdLocalizacion = document.createElement("td");
    const textoTitulo = document.createElement("div");
    const textoDescripcion = document.createElement("div");
    const textoLocalizacion = document.createElement("div");
    tdId.textContent = evento.id;
    textoTitulo.textContent = evento.titulo;
    textoDescripcion.textContent = evento.descripcion;
    textoLocalizacion.textContent = evento.localizacion;
    textoTitulo.classList.add("texto-3lineas");
    textoDescripcion.classList.add("descripcion-corta");
    textoLocalizacion.classList.add("texto-3lineas");
    tdTitulo.appendChild(textoTitulo);
    tdDescripcion.appendChild(textoDescripcion);
    tdLocalizacion.appendChild(textoLocalizacion);
    tdFechaInicio.textContent = formatearFecha(evento["fechaInicio"]);
    tdFechaFin.textContent = formatearFecha(evento["fechaFin"]);
    tdTitulo.classList.add("text-light");
    tdDescripcion.classList.add("text-light");
    tdFechaInicio.classList.add("text-light");
    tdFechaFin.classList.add("text-light");
    tdLocalizacion.classList.add("text-light");
    tr.appendChild(tdId);
    tr.appendChild(tdTitulo);
    tr.appendChild(tdDescripcion);
    tr.appendChild(tdFechaInicio);
    tr.appendChild(tdFechaFin);
    tr.appendChild(tdLocalizacion);
    tr.classList.add("evento");
    const tdAcciones = document.createElement("td");
    const divGrupo = document.createElement("div");
    divGrupo.className = "btn-group";
    divGrupo.setAttribute("role", "group");

    // Botón ver
    const btnVer = document.createElement("button");
    btnVer.className = "btn btn-sm btn-primary";
    btnVer.innerHTML = '<i class="fa-solid fa-eye"></i>';
    btnVer.setAttribute("data-bs-toggle", "modal");
    btnVer.setAttribute("data-bs-target", "#modalVerEvento");
    btnVer.addEventListener("click", function () {
      document.getElementById("contenidoModalEvento").innerHTML = `
                <h4 class="text-center">${evento.titulo}<br></h4>
                <img src="${evento.foto}" alt="${evento.titulo}" class="img-fluid img-thumbnail img-evento-modal mt-3 mb-2"><br>
                <p class="mb-1"><strong>Descripción:</strong> ${evento.descripcion}</p>
                <p><b>Fecha inicio:</b> ${formatearFecha(evento.fechaInicio)}</p>
                <p><b>Fecha fin:</b> ${formatearFecha(evento.fechaFin)}</p>
                <p><b>Organizador:</b> ${evento.emailUsuario}</p>
                <p><b>Categoría:</b> ${evento.nombreCategoria}</p>
                <p><b>Localización:</b> ${evento.localizacion}</p>
                ${mapa}`;
    });

    let mapa = "";
    if (evento.latitud && evento.longitud) {
      const lat = parseFloat(evento.latitud);
      const lon = parseFloat(evento.longitud);
      const delta = 0.0002; // Menos zoom: aumentar este valor si quieres ver más área
      const bbox = [
        lon - delta, // oeste
        lat - delta, // sur
        lon + delta, // este
        lat + delta, // norte
      ].join(",");
      mapa = `<div style="width:100%;max-width:320px;margin:auto">
                            <iframe width="400" height="280" style="border-radius:10px;border:0;" frameborder="0" scrolling="no" marginheight="0" marginwidth="0"
                                src="https://www.openstreetmap.org/export/embed.html?bbox=${bbox}&layer=mapnik&marker=${lat},${lon}">
                            </iframe>
                        </div>`;
    } else {
      mapa =
        '<div class="text-center text-warning">No hay coordenadas para este evento.</div>';
    }

    // Botón editar
    const btnEditar = document.createElement("button");
    btnEditar.className = "btn btn-sm btn-warning";
    btnEditar.innerHTML = '<i class="fa-solid fa-pen"></i>';
    btnEditar.setAttribute("data-id", evento.id);
    btnEditar.setAttribute("data-bs-toggle", "modal");
    btnEditar.setAttribute("data-bs-target", "#modalEditarEvento");
    btnEditar.addEventListener("click", function () {
      document.getElementById("formEditarEvento").dataset.id = evento.id;
      document.getElementById("tituloEventoEditar").value = evento.titulo;
      document.getElementById("descripcionEventoEditar").value =
        evento.descripcion;
      document.getElementById("fechaInicioEditar").value =
        evento.fechaInicio.substring(0, 10);
      document.getElementById("horaInicioEditar").value =
        evento.fechaInicio.substring(11, 16);
      document.getElementById("fechaFinEditar").value =
        evento.fechaFin.substring(0, 10);
      document.getElementById("horaFinEditar").value =
        evento.fechaFin.substring(11, 16);
      document.getElementById("localizacionEditar").value = evento.localizacion;
      const selectCategoriasEditar =
        document.getElementById("categoriasEditar");
      selectCategoriasEditar.value = evento.nombreCategoria;
      if (selectCategoriasEditar.value !== evento.nombreCategoria) {
        const opcion = Array.from(selectCategoriasEditar.options).find(
          (opt) =>
            opt.textContent.trim() === String(evento.nombreCategoria).trim(),
        );
        if (opcion) {
          selectCategoriasEditar.value = opcion.value;
        }
      }
      document.getElementById("imagenEvento").src = evento.foto;
    });

    // Botón eliminar
    const btnEliminar = document.createElement("button");
    btnEliminar.className = "btn btn-sm btn-danger";
    btnEliminar.innerHTML = '<i class="fa-solid fa-trash"></i>';
    btnEliminar.setAttribute("data-id", evento.id);
    btnEliminar.setAttribute("data-nombre", evento.titulo);
    btnEliminar.addEventListener("click", function () {
      eliminarEvento(this.dataset.id, this.dataset.nombre);
    });

    divGrupo.appendChild(btnVer);
    divGrupo.appendChild(btnEditar);
    divGrupo.appendChild(btnEliminar);
    tdAcciones.appendChild(divGrupo);
    tr.appendChild(tdAcciones);
    tabla.appendChild(tr);
  });

  cantidadPaginacion = data["totalPages"] ?? 0;
  console.log(cantidadPaginacion);
  cargarPaginacion(cantidadPaginacion, paginaActual);
}

function cargarPaginacion(totalPaginas, paginaActual) {
  const lista = document.getElementById("paginacion");
  const btnAnterior = document.getElementById("btnAnterior");
  const btnSiguiente = document.getElementById("btnSiguiente");

  if (totalPaginas === 0) {
    lista.style.display = "none";
    return;
  }

  lista.style.display = "flex";

  lista
    .querySelectorAll(".pagina-numero, .ellipsis")
    .forEach((el) => el.remove());

  const MAX_VISIBLE = 10;
  const mitad = Math.floor(MAX_VISIBLE / 2);

  let inicio = Math.max(0, paginaActual - mitad);
  let fin = Math.min(totalPaginas - 1, inicio + MAX_VISIBLE - 1);

  if (fin - inicio < MAX_VISIBLE - 1) {
    inicio = Math.max(0, fin - MAX_VISIBLE + 1);
  }

  btnAnterior.classList.toggle("disabled", paginaActual === 0);

  if (inicio > 0) {
    insertarPagina(lista, 0);
    insertarPuntos(lista);
  }

  for (let i = inicio; i <= fin; i++) {
    insertarPagina(lista, i, paginaActual);
  }

  if (fin < totalPaginas - 1) {
    insertarPuntos(lista);
    insertarPagina(lista, totalPaginas - 1, paginaActual);
  }

  btnSiguiente.classList.toggle("disabled", paginaActual === totalPaginas - 1);
}

function insertarPagina(lista, indice, paginaActual) {
  const li = document.createElement("li");
  li.classList.add("page-item", "pagina-numero");

  if (indice === paginaActual) li.classList.add("active");

  const a = document.createElement("a");
  a.classList.add("page-link");
  a.href = "#";
  a.textContent = indice + 1;

  a.addEventListener("click", (e) => {
    e.preventDefault();
    avanzarPagina(indice);
  });

  li.appendChild(a);
  lista.insertBefore(li, document.getElementById("btnSiguiente"));
}

function insertarPuntos(lista) {
  const li = document.createElement("li");
  li.classList.add("page-item", "ellipsis");

  const span = document.createElement("span");
  span.classList.add("page-link");
  span.textContent = "…";

  li.appendChild(span);
  lista.insertBefore(li, document.getElementById("btnSiguiente"));
}

function actualizarBotones() {
  const btnAnterior = document.getElementById("btnAnterior");
  const btnSiguiente = document.getElementById("btnSiguiente");

  btnAnterior.classList.toggle("disabled", paginaActual === 0);
  btnSiguiente.classList.toggle(
    "disabled",
    paginaActual === cantidadPaginacion - 1,
  );
}

function avanzarPagina(indice) {
  paginaActual = indice;
  cargarEventos();
  actualizarBotones();
}

async function obtenerCategorias() {
  const selectCrear = document.getElementById("categorias");
  const selectEditar = document.getElementById("categoriasEditar");

  try {
    const resp = await fetch(URL_BASE + "categorias/all", {
      method: "GET",
      headers: {
        "Content-Type": "application/json",
      },
      credentials: "include",
    });

    if (!resp.ok) {
      throw new Error("Error al obtener los categorías");
    }

    const data = await resp.json();
    const selects = [selectCrear, selectEditar].filter(Boolean);

    selects.forEach((select) => {
      const placeholder = select.querySelector("option[value='']");
      select.innerHTML = "";
      if (placeholder) {
        select.appendChild(placeholder);
      }
      data.forEach((categoria) => {
        const opt = document.createElement("option");
        opt.value = categoria["nombre"];
        opt.textContent = categoria["nombre"];
        select.appendChild(opt);
      });
    });
  } catch (error) {
    console.error("Error al cargar las categorías:", error);
  }
}

async function subirEvento(datosFormulario) {
  try {
    const options = {
      method: "POST",
      body: datosFormulario,
    };
    const resp = await fetch(URL_BASE + "eventos/addWithImage", options);
    const respuesta = await resp.json();
    if (resp.status === 201) {
      mostrarAlerta("success", "Evento creado correctamente");
    } else {
      mostrarAlerta("error", "Error al crear el evento: " + respuesta.error);
    }
  } catch (error) {
    console.error("Error al subir el evento:", error);
  }
}

async function editarEvento(id, datosFormulario) {
  try {
    const options = {
      method: "PUT",
      body: datosFormulario,
    };
    const resp = await fetch(URL_BASE + "eventos/update/" + id, options);
    const respuesta = await resp.json();
    if (resp.status === 200) {
      mostrarAlerta("success", "Evento editado correctamente");
    } else {
      mostrarAlerta("error", "Error al editar el evento: " + respuesta.error);
    }
  } catch (error) {
    console.error("Error al editar el evento:", error);
  }
}

async function eliminarEvento(id, nombre) {
  Swal.fire({
    title: `¿Estás seguro que deseas eliminar el evento \"` + nombre + `\"?`,
    text: "Esta acción no puede revertirse",
    icon: "warning",
    showCancelButton: true,
    cancelButtonColor: "#3085d6",
    cancelButtonText: "Cancelar",
    confirmButtonColor: "#d33",
    confirmButtonText: "Eliminar evento",
  }).then(async (result) => {
    if (result.isConfirmed) {
      try {
        const options = {
          method: "DELETE",
        };
        const resp = await fetch(URL_BASE + "eventos/delete/" + id, options);
        if (resp.status === 204) {
          mostrarAlerta("success", "Evento eliminado correctamente");
        } else {
          mostrarAlerta(
            "error",
            "Error al eliminar el evento: " + respuesta.error,
          );
        }
      } catch (error) {
        console.error("Error al eliminar el evento:", error);
      }
    }
  });
}

function asociarIdCategoria(nombreCategoria) {
  switch (nombreCategoria) {
    case "Conciertos y Música":
      return 1;
    case "Festivales y Ferias":
      return 2;
    case "Cine y Teatro":
      return 3;
    case "Exposiciones y Arte":
      return 4;
    case "Gastronomía":
      return 5;
    case "Conferencias, Talleres y Cursos":
      return 6;
    case "Deportes y Actividad Física":
      return 7;
    case "Fiestas y Vida Nocturna":
      return 8;
    case "Familia e Infantil":
      return 9;
    case "Tecnología y Ciencia":
      return 10;
    case "Solidaridad y Causas Sociales":
      return 11;
    default:
      return 12;
  }
}

function formatearFecha(fechaISO) {
  const fecha = new Date(fechaISO);
  const dia = fecha.getDate().toString().padStart(2, "0");
  const mes = (fecha.getMonth() + 1).toString().padStart(2, "0");
  const anio = fecha.getFullYear();
  const hora = fecha.getHours().toString().padStart(2, "0");
  const minutos = fecha.getMinutes().toString().padStart(2, "0");
  return `${dia}/${mes}/${anio} - ${hora}:${minutos}`;
}
