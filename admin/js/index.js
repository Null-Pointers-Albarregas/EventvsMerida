window.addEventListener("DOMContentLoaded", async (event) => {
  const nombreUsuario = localStorage.getItem("nombreUsuario");
  mostrarAlerta("info", "Bienvenid@ de nuevo", nombreUsuario);
});
