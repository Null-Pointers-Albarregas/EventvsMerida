# Eventvs Mérida — Landing Page

Landing page oficial de la aplicación **Eventvs Mérida**, desarrollada con **Angular 19**.

## 🚀 Instalación y arranque

### Requisitos
- Node.js 18+ 
- npm 9+

### Pasos

```bash
# 1. Instalar dependencias
npm install

# 2. Copiar el logo al directorio public
# Coloca el archivo logo.jpeg en: public/assets/logo.jpeg

# 3. Arrancar en desarrollo
npm start

# 4. Build de producción
npm run build
```

La app arrancará en `http://localhost:4200`

## 📁 Estructura del proyecto

```
src/
├── app/
│   ├── components/
│   │   ├── navbar/          # Navbar fija con scroll detection
│   │   ├── hero/            # Hero con parallax y animaciones de entrada
│   │   ├── about/           # Sección "Qué es la app"
│   │   ├── features/        # Grid de funcionalidades
│   │   ├── team/            # Tarjetas del equipo
│   │   └── download/        # Descarga APK + repo + footer
│   └── directives/
│       └── reveal.directive.ts  # Scroll-reveal con IntersectionObserver
├── styles.scss              # Estilos globales + variables CSS
└── index.html
```

## ✨ Animaciones implementadas

- **Hero**: Entrada escalonada de título, subtítulo y CTAs con `@keyframes`
- **Parallax**: El fondo del hero hace parallax al hacer scroll
- **Scroll reveal**: Cada sección aparece con física suave al entrar en viewport (Intersection Observer)
- **Hover effects**: Cards con lift, glow y líneas animadas
- **Particles**: Partículas flotantes en el hero
- **Orbs**: Esferas de luz animadas en fondos

## 🎨 Diseño

- **Colores**: Dorado `#F5A623` + Azul `#2B6CB0` (del logo)
- **Tipografías**: Bebas Neue (títulos) + Barlow (cuerpo) + Barlow Condensed (UI)
- **Tema**: Dark con efectos cinematográficos

## 📲 Links

- **Repositorio**: https://github.com/Null-Pointers-Albarregas/EventvsMerida
- **APK**: https://github.com/Null-Pointers-Albarregas/EventvsMerida/releases/download/Alpha/eventvs-merida.apk

---

Desarrollado por **Adrián Pérez Morales**, **David Muñoz Collado** y **Eva Retamar Muñoz**  
IES Albarregas · Mérida, Extremadura
