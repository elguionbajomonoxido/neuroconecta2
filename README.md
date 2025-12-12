# NeuroConecta

**Versión:** 1.1.0  
**Tecnología:** Flutter (Dart) + Firebase

---

## Sobre el Proyecto

NeuroConecta es una app inclusiva diseñada para apoyar a personas neurodivergentes y con capacidades especiales. Ofrece cápsulas educativas, contenido multimedia accesible, temas visuales adaptativos, controles de reproducción intuitivos y configuraciones de accesibilidad avanzadas (como escala de texto y modos para daltónicos). Su objetivo es facilitar el aprendizaje y la comunicación de manera accesible, útil y amigable.

---

## Nuevas Integraciones (v1.1.0)

### Visualizador Multimedia Universal

Hemos potenciado la experiencia de aprendizaje con un nuevo reproductor multimedia robusto:

- **Soporte de Enlaces:** Ahora las cápsulas pueden incluir enlaces directos a videos o imágenes.
- **Reproductor de Video Mejorado:** Integración de `video_player` y `chewie` para ofrecer controles de reproducción amigables, pantalla completa y carga fluida.
- **Visor de Imágenes:** Carga optimizada de imágenes desde internet con caché (`cached_network_image`) para ahorrar datos y mejorar la velocidad.

---

## Características Principales

- **Gestión de Cápsulas:** Creación, edición y visualización de contenido educativo segmentado (Niños, Adolescentes, Adultos).
- **Accesibilidad Total:**
  - Temas de color adaptables (Lavanda, Azul Calma, etc.).
  - Modos para daltónicos (Protanopía, Deuteranopía, Tritanopía).
  - Ajuste de tamaño de texto dinámico.
- **Roles de Usuario:** Sistema seguro con roles de Administrador (creadores de contenido) y Usuarios (lectores).
- **Retroalimentación Social:** Sistema de valoraciones (estrellas) y comentarios para mejorar el contenido continuamente.

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

- **Flutter SDK:** (Versión estable 3.24+)
- **Git**
- **Cuenta de Firebase** configurada.

### 2. Configuración Inicial

~~~bash
# 1. Clonar el repositorio
git clone <URL_DEL_REPO>
cd neuroconecta2

# 2. Instalar dependencias (incluyendo las nuevas de video)
flutter pub get
~~~

### 3. Configuración de Firebase

El proyecto requiere el archivo `firebase_options.dart` o los archivos de configuración nativos (`google-services.json` / `GoogleService-Info.plist`).

**Opción recomendada (FlutterFire CLI):**
~~~bash
flutterfire configure
~~~

### 4. Ejecución

~~~bash
flutter run
~~~

---

## Contribución

Este proyecto está pensado para la comunidad. Si deseas contribuir, por favor asegúrate de probar las funcionalidades de accesibilidad antes de enviar tu PR.

---

*Desarrollado con ❤️ para la inclusión.*
