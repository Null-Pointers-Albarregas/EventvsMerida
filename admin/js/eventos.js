window.addEventListener("DOMContentLoaded", async (event) => {
    const URL_BASE = "https://eventvsmerida.onrender.com/api/";
    obtenerCategorias(URL_BASE);
    cargarEventos(URL_BASE);

    const form = document.getElementById("formAgregarEvento");

    form.addEventListener("submit", function (event) {
        if (!form.checkValidity()) {
            event.preventDefault();
            event.stopPropagation();
            form.classList.add("was-validated"); // Esto activa los mensajes de error de Bootstrap
        } else {
            event.preventDefault();
            console.log(document.getElementById("fechaFin").value)
            const datosFormulario = {
                titulo: document.getElementById("titulo").value,
                descripcion: document.getElementById("descripcion").value,
                fechaInicio: document.getElementById("fechaInicio").value + "T" + document.getElementById("horaInicio").value + ":00.000Z",
                fechaFin: document.getElementById("fechaFin").value + "T" + document.getElementById("horaFin").value + ":00.000Z",
                localizacion: document.getElementById("localizacion").value,
                foto: document.getElementById("fotoEvento").value,
                idUsuario: 3,
                idCategoria: asociarIdCategoria(document.getElementById("categorias").value),
            };
            subirEvento(URL_BASE, datosFormulario);
        }
        form.classList.add("was-validated");
    }, false);
});

async function cargarEventos(URL_BASE) {
    const tabla = document.getElementById("listadoEventos");
    const loader = document.getElementById("loader");

    try {
        loader.style.display = "flex";

        const resp = await fetch(URL_BASE + "eventos/all", {
            method: "GET",
            headers: {
                "Content-Type": "application/json",
            },
        });

        const data = await resp.json();
        data.forEach((evento) => {
            const tr = document.createElement("tr");
            const tdTitulo = document.createElement("td");
            const tdDescripcion = document.createElement("td");
            const tdFechaInicio = document.createElement("td");
            const tdFechaFin = document.createElement("td");
            const tdLocalizacion = document.createElement("td");
            tdTitulo.textContent = evento["titulo"];
            tdDescripcion.textContent = evento["descripcion"];
            tdFechaInicio.textContent = formatearFecha(evento["fechaInicio"]);
            tdFechaFin.textContent = formatearFecha(evento["fechaFin"]);
            tdLocalizacion.textContent = evento["localizacion"];
            tdTitulo.classList.add("text-light");
            tdDescripcion.classList.add("text-light");
            tdDescripcion.classList.add("descripcion-corta");
            tdFechaInicio.classList.add("text-light");
            tdFechaFin.classList.add("text-light");
            tdLocalizacion.classList.add("text-light");
            tr.appendChild(tdTitulo);
            tr.appendChild(tdDescripcion);
            tr.appendChild(tdFechaInicio);
            tr.appendChild(tdFechaFin);
            tr.appendChild(tdLocalizacion);
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
                <p><b>Localización:</b> ${evento.localizacion}</p>
                <p><b>Organizador:</b> ${evento.emailUsuario}</p>
                <p><b>Categoría:</b> ${evento.nombreCategoria}</p>`;
            });

            // Botón editar
            const btnEditar = document.createElement("button");
            btnEditar.className = "btn btn-sm btn-warning";
            btnEditar.innerHTML = '<i class="fa-solid fa-pen"></i>';
            btnEditar.setAttribute("data-id", evento.id);
            btnEditar.setAttribute("data-bs-toggle", "modal");
            btnEditar.setAttribute("data-bs-target", "#modalEditarEvento");
            btnEditar.addEventListener("click", function () {
                console.log(evento.titulo);
                document.getElementById("tituloEvento").value = evento.titulo;
                document.getElementById("descripcionEvento").value = evento.descripcion;
                console.log(evento.fechaInicio.split("T")[0]);
                document.getElementById("fechaInicio").value = evento.fechaInicio.split("T")[0];
                document.getElementById("horaInicio").value = evento.fechaInicio.split("T")[1];
                document.getElementById("fechaFin").value = evento.fechaFin.split("T")[0];
                document.getElementById("horaFin").value = evento.fechaFin.split("T")[1];
                document.getElementById("localizacionEvento").value = evento.localizacion;
                console.log(evento.nombreCategoria);
                document.getElementById("categoriasEvento").value = evento.nombreCategoria;
                document.getElementById("imagenEvento").src = evento.foto;
            });

            // Botón eliminar
            const btnEliminar = document.createElement("button");
            btnEliminar.className = "btn btn-sm btn-danger";
            btnEliminar.innerHTML = '<i class="fa-solid fa-trash"></i>';
            btnEliminar.setAttribute("data-id", evento.id);
            btnEliminar.addEventListener("click", function () {
                eliminarEvento();
            });

            divGrupo.appendChild(btnVer);
            divGrupo.appendChild(btnEditar);
            divGrupo.appendChild(btnEliminar);
            tdAcciones.appendChild(divGrupo);
            tr.appendChild(tdAcciones);
            tabla.appendChild(tr);
            tabla.appendChild(tr);
        });
    } catch (error) {
        console.error("Error al cargar los eventos:", error);
    } finally {
        loader.style.display = "none";
    }
}

async function obtenerCategorias(URL_BASE) {
    const select = document.getElementById("categorias");
    const selectEditar = document.getElementById("categoriasEvento");

    try {
        const resp = await fetch(URL_BASE + "categorias/all", {
            method: "GET",
            headers: {
                "Content-Type": "application/json",
            },
        });

        if (!resp.ok) {
            throw new Error("Error al obtener las categorías");
        }

        const data = await resp.json();
        data.forEach((categoria) => {
            const opt = document.createElement("option");
            opt.value = categoria["nombre"];
            opt.textContent = categoria["nombre"];
            select.appendChild(opt);
            const optEditar = document.createElement("option");
            optEditar.value = categoria["nombre"];
            optEditar.textContent = categoria["nombre"];
            selectEditar.appendChild(optEditar);
        });
    } catch (error) {
        console.error("Error al cargar las categorías:", error);
    }
}

async function subirEvento(URL_BASE, datosFormulario) {
    try {
        const resp = await fetch(URL_BASE + "eventos/add", {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
            },
            body: JSON.stringify(datosFormulario),
        });

        const respuesta = await resp.json();
        if (resp.status === 201) {
            mostrarAlerta("success", "Evento creado correctamente");
        } else {
            mostrarAlerta("error", "Error al crear el evento: " + respuesta.message);
        }
    } catch (error) {
        console.error("Error al subir el evento:", error);
    }
}

function eliminarEvento() {
    Swal.fire({
        title: "¿Estás seguro que deseas eliminar el evento?",
        text: "Esta acción no puede revertirse",
        icon: "warning",
        showCancelButton: true,
        cancelButtonColor: "#3085d6",
        cancelButtonText: "Cancelar",
        confirmButtonColor: "#d33",
        confirmButtonText: "Eliminar evento"
    }).then((result) => {
        if (result.isConfirmed) {
            mostrarAlerta("success", "Evento eliminado correctamente");
        }
    });
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