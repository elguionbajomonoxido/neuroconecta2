# NeuroConecta

**Versión:** 1.2.0  
**Tecnología:** Flutter (Dart) + Firebase

---

## Sobre el Proyecto

NeuroConecta es una app inclusiva diseñada para apoyar a personas neurodivergentes y con capacidades especiales. Ofrece cápsulas educativas, contenido multimedia accesible, temas visuales adaptativos, controles de reproducción intuitivos y configuraciones de accesibilidad avanzadas (como escala de texto y modos para daltónicos). Su objetivo es facilitar el aprendizaje y la comunicación de manera accesible, útil y amigable.

---

## Novedades (v1.2.0)

- **Favoritos con sincronización y modo offline:** agrega/quita favoritos con UI optimista y sincronización en segundo plano.
- **Panel de Guías (admins):** creación y edición de guías con bloques (texto e imagen) y vista previa en vivo.
- **Editor de groserías (admins):** gestión centralizada de la lista de palabras censuradas.
- **Modo Niños:** filtra cápsulas para mostrar solo contenido apto.
- **Retroalimentación mejorada:** validación de groserías y vista compacta cuando el usuario ya comentó.
- **Visualizador Multimedia Universal:** soporte de enlaces (video/imágenes), `video_player` + `chewie`, imágenes con caché.

---

## Características Principales

- **Gestión de Cápsulas:** Creación, edición y visualización de contenido segmentado (Niños, Adolescentes, Adultos).
- **Accesibilidad Total:**
  - Temas de color adaptables.
  - Modos para daltónicos (Protanopía, Deuteranopía, Tritanopía).
  - Ajuste de tamaño de texto dinámico.
- **Roles de Usuario:** Administrador y Usuario lector.
- **Retroalimentación Social:** Valoraciones (estrellas) y comentarios con filtros de lenguaje.

---

## Stack Tecnológico

- **Frontend:** Flutter y Dart
- **Backend:** Firebase (Auth, Firestore)
- **Multimedia:** `video_player`, `chewie`, `cached_network_image`
- **Navegación:** `go_router`
- **Estado:** `provider`

---

## Guía de Instalación y Despliegue

### 1. Requisitos Previos
- Flutter SDK (versión estable 3.24+)
- Git
- Cuenta de Firebase configurada.

### 2. Configuración Inicial
```bash
git clone <URL_DEL_REPO>
cd neuroconecta2
flutter pub get
```

### 3. Configuración de Firebase
```bash
flutterfire configure
```
(O usa los archivos nativos `google-services.json` / `GoogleService-Info.plist`).

### 4. Ejecución
```bash
flutter run
```

---

## Contribución

Este proyecto está pensado para la comunidad. Prueba las funcionalidades de accesibilidad antes de enviar tu PR.

---

*Desarrollado con ❤️ para la inclusión.*
