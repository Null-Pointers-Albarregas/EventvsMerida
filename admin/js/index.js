window.addEventListener("DOMContentLoaded", async () => {
  const sesion = await logeado();

  if (sesion === 401) {
    window.location.href = `${window.location.origin}/html/login.html`;
    return;
  } else if (sesion === 200){
    document.body.classList.remove("auth-pending");
  }

  const nombreUsuario = obtenerNombreUsuario();
  if(document.referrer.includes("/html/login.html")) {
    mostrarAlerta("info", `Bievenid@ de nuevo ${nombreUsuario}`)
  }


  const URL_BASE = "https://eventvsmerida.onrender.com/api/";
  cargarDashboard(URL_BASE);
});

async function cargarDashboard(URL_BASE) {
  try {
    const [
      usuarios,
      eventos,
      organizadores,
      categorias,
      roles
    ] = await Promise.all([
      fetch(URL_BASE + "usuarios/count/registered", { credentials: "include" }).then(r => r.text()),
      fetch(URL_BASE + "eventos/count").then(r => r.text()),
      fetch(URL_BASE + "usuarios/count/organizers", { credentials: "include" }).then(r => r.text()),
      fetch(URL_BASE + "categorias/count").then(r => r.text()),
      fetch(URL_BASE + "roles/count", { credentials: "include" }).then(r => r.text()),
    ]);

    animarContador(document.getElementById("numUsuarios"), Number(usuarios));
    animarContador(document.getElementById("numEventos"), Number(eventos));
    animarContador(document.getElementById("numOrganizadores"), Number(organizadores));
    animarContador(document.getElementById("numCategorias"), Number(categorias));
    animarContador(document.getElementById("numRoles"), Number(roles));

  } catch (error) {
    console.error("Error al cargar el dashboard:", error);
  }
}

function animarContador(elemento, valorFinal, duracion = 1300) {
  let inicio = 0;
  const incrementoTiempo = 20;
  const incremento = Math.ceil(valorFinal / (duracion / incrementoTiempo));

  const intervalo = setInterval(() => {
    inicio += incremento;

    if (inicio >= valorFinal) {
      inicio = valorFinal;
      clearInterval(intervalo);
    }

    elemento.textContent = inicio;
  }, incrementoTiempo);
}