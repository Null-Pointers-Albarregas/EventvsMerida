/*!
 * Start Bootstrap - SB Admin v7.0.7 (https://startbootstrap.com/template/sb-admin)
 * Copyright 2013-2023 Start Bootstrap
 * Licensed under MIT (https://github.com/StartBootstrap/startbootstrap-sb-admin/blob/master/LICENSE)
 */
//
// Scripts
//

window.addEventListener("DOMContentLoaded", async (event) => {
  // Toggle the side navigation
  const sidebarToggle = document.body.querySelector("#sidebarToggle");
  if (sidebarToggle) {
    // Uncomment Below to persist sidebar toggle between refreshes
    // if (localStorage.getItem('sb|sidebar-toggle') === 'true') {
    //     document.body.classList.toggle('sb-sidenav-toggled');
    // }
    sidebarToggle.addEventListener("click", (event) => {
      event.preventDefault();
      document.body.classList.toggle("sb-sidenav-toggled");
      localStorage.setItem(
        "sb|sidebar-toggle",
        document.body.classList.contains("sb-sidenav-toggled"),
      );
    });
  }

  const URL_BASE = "https://eventvsmerida.onrender.com/api/";

  const select = document.getElementById("roles");

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

  const tabla = document.getElementById("listadoEventos");
    try {
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
            tdFechaInicio.textContent = new Date(evento["fecha_inicio"]).toLocaleDateString();
            tdFechaFin.textContent = new Date(evento["fecha_fin"]).toLocaleDateString();
            tdLocalizacion.textContent = evento["localizacion"];
            tdTitulo.classList.add("text-light");
            tdDescripcion.classList.add("text-light");
            tdDescripcion.classList.add("descripcion-corta")
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
btnVer.addEventListener("click", function() {
  // Rellena el contenido del modal con los datos del evento
  document.getElementById("contenidoModalEvento").innerHTML = `
    <strong>Título:</strong> ${evento.titulo}<br>
    <img src="${evento.foto}" alt="${evento.titulo}" class="img-fluid mb-3"><br>
    <strong>Descripción:</strong> ${evento.descripcion}<br>
    <strong>Fecha inicio:</strong> ${evento.fecha_inicio}<br>
    <strong>Fecha fin:</strong> ${evento.fecha_fin}<br>
    <strong>Localización:</strong> ${evento.localizacion}
  `;
});

    // Botón editar
    const btnEditar = document.createElement("button");
    btnEditar.className = "btn btn-sm btn-warning";
    btnEditar.innerHTML = '<i class="fa-solid fa-pen"></i>';
    btnEditar.setAttribute("data-id", evento.id);
    btnEditar.addEventListener("click", function() {
        // Acción para editar
        alert("Editar evento: " + evento.titulo);
        // O abre un formulario de edición
    });

    // Botón eliminar
    const btnEliminar = document.createElement("button");
    btnEliminar.className = "btn btn-sm btn-danger";
    btnEliminar.innerHTML = '<i class="fa-solid fa-trash"></i>';
    btnEliminar.setAttribute("data-id", evento.id);
    btnEliminar.addEventListener("click", function() {
        // Acción para eliminar
        if (confirm("¿Seguro que quieres eliminar el evento: " + evento.titulo + "?")) {
            // Aquí llamas a tu API para eliminar
            alert("Evento eliminado (simulado)");
        }
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
    }
    
});

function mostrarAlerta(tipo, mensaje) {
  const Toast = Swal.mixin({
    toast: true,
    position: "top-end",
    iconColor: "white",
    customClass: {
      popup: "colored-toast",
    },
    showConfirmButton: false,
    timer: 1500,
    timerProgressBar: true,
  });

  Toast.fire({
    icon: tipo,
    title: mensaje,
  });
}

// Validación Bootstrap para formularios
(() => {
  "use strict";
  const forms = document.querySelectorAll(".needs-validation");
  Array.from(forms).forEach((form) => {
    form.addEventListener(
      "submit",
      (event) => {
        if (!form.checkValidity()) {
          event.preventDefault();
          event.stopPropagation();
        }
        form.classList.add("was-validated");
      },
      false,
    );
  });
})();