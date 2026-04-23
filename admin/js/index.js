window.addEventListener("DOMContentLoaded", async (event) => {
  mostrarAlerta = true;

  if (mostrarAlerta) {
    const nombreUsuario = localStorage.getItem("nombreUsuario");
    mostrarAlerta("info", `Bienvenid@ de nuevo ${nombreUsuario}`);
    mostrarAlerta = false;
  }
});
