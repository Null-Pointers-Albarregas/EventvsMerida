window.addEventListener("DOMContentLoaded", async (event) => {
    const URL_BASE = "https://eventvsmerida.onrender.com/api/";
    cargarEventos(URL_BASE);
    obtenerCategorias(URL_BASE);

    // Buscador de eventos provisional
    document.addEventListener("keyup", e => {
        if (e.target.matches('#buscador')) {
            document.querySelectorAll('.evento').forEach(evento => {
                evento.textContent.toLowerCase().includes(e.target.value) ? evento.classList.remove('filtro') : evento.classList.add('filtro');
            })
        }
    });

    const form = document.getElementById("formAgregarEvento");

    form.addEventListener("submit", function (event) {
        if (!form.checkValidity()) {
            event.preventDefault();
            event.stopPropagation();
            form.classList.add("was-validated");
        } else {
            event.preventDefault();
            const evento = {
                titulo: document.getElementById("titulo").value,
                descripcion: document.getElementById("descripcion").value,
                fechaInicio: document.getElementById("fechaInicio").value + "T" + document.getElementById("horaInicio").value + ":00.000",
                fechaFin: document.getElementById("fechaFin").value + "T" + document.getElementById("horaFin").value + ":00.000",
                localizacion: document.getElementById("localizacion").value,
                idUsuario: 3,
                idCategoria: asociarIdCategoria(document.getElementById("categorias").value)
            };
            const formData = new FormData();
            formData.append("evento", JSON.stringify(evento));
            formData.append("foto", document.getElementById("fotoEvento").files[0]);
            subirEvento(URL_BASE, formData, true);
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

        // Mostrar mensaje si no hay eventos y limpiar tabla
        const eventosVacio = document.getElementById('eventos-vacio');
        if ( data.length === 0) {
            eventosVacio.classList.remove("d-none");
            eventosVacio.classList.add("d-block");
          tabla.innerHTML = "";
            return;
        } else {
            eventosVacio.classList.remove("d-block");
            eventosVacio.classList.add("d-none");
        }

        data.forEach((evento) => {
            const tr = document.createElement("tr");
            const tdTitulo = document.createElement("td");
            const tdDescripcion = document.createElement("td");
            const tdFechaInicio = document.createElement("td");
            const tdFechaFin = document.createElement("td");
            const tdLocalizacion = document.createElement("td");
            const textoTitulo = document.createElement("div");
            const textoDescripcion = document.createElement("div");
            const textoLocalizacion = document.createElement("div");
            textoTitulo.textContent = evento["titulo"];
            textoDescripcion.textContent = evento["descripcion"];
            textoLocalizacion.textContent = evento["localizacion"];
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
            tr.appendChild(tdTitulo);
            tr.appendChild(tdDescripcion);
            tr.appendChild(tdFechaInicio);
            tr.appendChild(tdFechaFin);
            tr.appendChild(tdLocalizacion);
            tr.classList.add("evento")
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
                ${mapa}`


            });

            let mapa = '';
            if (evento.latitud && evento.longitud) {
                const lat = parseFloat(evento.latitud);
                const lon = parseFloat(evento.longitud);
                const delta = 0.0002; // Menos zoom: aumentar este valor si quieres ver más área
                const bbox = [
                    lon - delta, // oeste
                    lat - delta, // sur
                    lon + delta, // este
                    lat + delta  // norte
                ].join(',');
                mapa = `<div style="width:100%;max-width:320px;margin:auto">
                            <iframe width="400" height="280" style="border-radius:10px;border:0;" frameborder="0" scrolling="no" marginheight="0" marginwidth="0"
                                src="https://www.openstreetmap.org/export/embed.html?bbox=${bbox}&layer=mapnik&marker=${lat},${lon}">
                            </iframe>
                        </div>`;
            } else {
                mapa = '<div class="text-center text-warning">No hay coordenadas para este evento.</div>';
            }

            // Botón editar
            const btnEditar = document.createElement("button");
            btnEditar.className = "btn btn-sm btn-warning";
            btnEditar.innerHTML = '<i class="fa-solid fa-pen"></i>';
            btnEditar.setAttribute("data-id", evento.id);
            btnEditar.setAttribute("data-bs-toggle", "modal");
            btnEditar.setAttribute("data-bs-target", "#modalEditarEvento");
            btnEditar.addEventListener("click", function () {
                document.getElementById("tituloEventoEditar").value = evento.titulo;
                document.getElementById("descripcionEventoEditar").value = evento.descripcion;
                document.getElementById("fechaInicioEditar").value = evento.fechaInicio.substring(0, 10);
                document.getElementById("horaInicioEditar").value = evento.fechaInicio.substring(11, 16);
                document.getElementById("fechaFinEditar").value = evento.fechaFin.substring(0, 10);
                document.getElementById("horaFinEditar").value = evento.fechaFin.substring(11, 16);
                document.getElementById("localizacionEditar").value = evento.localizacion;
                const selectCategoriasEditar = document.getElementById("categoriasEditar");
                selectCategoriasEditar.value = evento.nombreCategoria;
                if (selectCategoriasEditar.value !== evento.nombreCategoria) {
                    const opcion = Array.from(selectCategoriasEditar.options).find((opt) => opt.textContent.trim() === String(evento.nombreCategoria).trim());
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
            btnEliminar.addEventListener("click", function () {
                eliminarEvento();
            });

            divGrupo.appendChild(btnVer);
            divGrupo.appendChild(btnEditar);
            divGrupo.appendChild(btnEliminar);
            tdAcciones.appendChild(divGrupo);
            tr.appendChild(tdAcciones);
            tabla.appendChild(tr);
        });
    } catch (error) {
        console.error("Error al cargar los eventos:", error);
    } finally {
        loader.style.display = "none";
    }
}

async function obtenerCategorias(URL_BASE) {
    const selectCrear = document.getElementById("categorias");
    const selectEditar = document.getElementById("categoriasEditar");

    try {
        const resp = await fetch(URL_BASE + "categorias/all", {
            method: "GET",
            headers: {
                "Content-Type": "application/json",
            },
        });

        if (!resp.ok) {
            throw new Error("Error al obtener los roles");
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

async function subirEvento(URL_BASE, datosFormulario) {
    try {
        const options = {
            method: "POST",
            body: datosFormulario
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

// async function eliminarEvento() {
//     Swal.fire({
//         title: "¿Estás seguro que deseas eliminar el evento?",
//         text: "Esta acción no puede revertirse",
//         icon: "warning",
//         showCancelButton: true,
//         cancelButtonColor: "#3085d6",
//         cancelButtonText: "Cancelar",
//         confirmButtonColor: "#d33",
//         confirmButtonText: "Eliminar evento"
//     }).then((result) => {
//         if (result.isConfirmed) {
//             try {
//                 const options = {
//                     method: "DELETE",
//                 };
//                 const resp = await fetch(URL_BASE + "eventos/delete", options);
//                 const respuesta = await resp.json();
//                 if (resp.status === 204) {
//                     mostrarAlerta("success", "Evento eliminado correctamente");
//                 } else {
//                     mostrarAlerta("error", "Error al eliminar el evento: " + respuesta.error);
//                 }
//             } catch (error) {
//                 console.error("Error al eliminar el evento:", error);
//             }
//         }
//     });
// }

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