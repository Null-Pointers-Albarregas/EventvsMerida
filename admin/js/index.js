window.addEventListener("DOMContentLoaded", async () => {
  const sesion = await logeado();

  if (sesion === 401) {
    window.location.href = `${window.location.origin}/html/login.html`;
    return;
  } else if (sesion === 200){
    document.body.classList.remove("auth-pending");
  }


  const URL_BASE = "https://eventvsmerida.onrender.com/api/";
  cargarDashboard(URL_BASE);

  document.getElementById("nombreUsuario").innerText = obtenerNombreUsuario();
});

async function cargarDashboard(URL_BASE) {
  try {
    const [usuarios, eventos, organizadores] = await Promise.all([
      fetch(URL_BASE + "usuarios/count/registrados").then((r) => r.text()),
      fetch(URL_BASE + "eventos/count").then((r) => r.text()),
      fetch(URL_BASE + "usuarios/count/organizadores").then((r) => r.text()),
    ]);

    document.getElementById("numUsuarios").textContent = usuarios;
    document.getElementById("numEventos").textContent = eventos;
    document.getElementById("numOrganizadores").textContent = organizadores;
  } catch (error) {
    console.error("Error al cargar el dashboard:", error);
  }
}