# 🧠 NeuroConecta - Manual Técnico y de Despliegue

**Versión:** 1.0.0  
**Fecha:** Diciembre 2025  
**Tecnología:** Flutter (Dart) + Firebase

---

## 📋 Introducción

Este documento es la guía definitiva para cualquier desarrollador (Junior o Senior) que necesite retomar, configurar, compilar o desplegar el proyecto **NeuroConecta**.

El proyecto es una aplicación móvil multiplataforma (Android/iOS) diseñada para brindar apoyo psicopedagógico mediante "Cápsulas" de contenido y un sistema de retroalimentación social.

---

## ⚙️ 1. Requisitos del Entorno (Prerrequisitos)

Antes de tocar una línea de código, asegúrate de tener instalado:

1.  **Flutter SDK:** Versión estable más reciente (probado en 3.24+).
    *   Verificar con: `flutter doctor`
2.  **Dart SDK:** Incluido con Flutter.
3.  **Editor de Código:** VS Code (recomendado con extensiones de Flutter/Dart) o Android Studio.
4.  **Git:** Para control de versiones.
5.  **Cuenta de Firebase:** Acceso a la consola de Firebase.
6.  **Java JDK 11 o 17:** Requerido para compilar en Android.

---

## 🚀 2. Instalación y Configuración Inicial

Sigue estos pasos estrictamente en orden para levantar el proyecto desde cero.

### Paso 2.1: Clonar y Dependencias

```bash
# 1. Clonar el repositorio
git clone <URL_DEL_REPO>
cd neuroconecta2

# 2. Instalar librerías de Dart
flutter pub get
```

### Paso 2.2: Configuración de Firebase (CRÍTICO)

El proyecto **NO funcionará** sin las credenciales de Firebase. Tienes dos opciones:

**Opción A: Usando FlutterFire CLI (Recomendada)**
Si tienes acceso a la cuenta de Google dueña del proyecto:
```bash
# Instalar CLI si no lo tienes
dart pub global activate flutterfire_cli

# Configurar (sigue las instrucciones en pantalla)
flutterfire configure
```
*Esto generará automáticamente el archivo `lib/firebase_options.dart` y colocará los archivos de configuración nativos.*

**Opción B: Manual (Archivos google-services)**
Si te pasan los archivos de credenciales:
1.  **Android:** Coloca el archivo `google-services.json` en `android/app/`.
2.  **iOS:** Coloca el archivo `GoogleService-Info.plist` en `ios/Runner/`.

### Paso 2.3: Configuración de Iconos y Nombre

Si necesitas cambiar la marca de la app:

1.  **Icono:**
    *   Coloca tu imagen (PNG 1024x1024) en `assets/icon/app_icon.png`.
    *   Ejecuta:
        ```bash
        flutter pub run flutter_launcher_icons:main
        ```
2.  **Nombre de la App:**
    *   **Android:** Edita `android/app/src/main/res/values/strings.xml`.
    *   **iOS:** Edita `ios/Runner/Info.plist` (clave `CFBundleDisplayName`).

---

## 📱 3. Ejecución y Desarrollo

### Comandos Básicos

*   **Correr en Debug (Emulador/Físico):**
    ```bash
    flutter run
    ```
*   **Limpiar caché (si algo falla raro):**
    ```bash
    flutter clean
    flutter pub get
    ```

### Roles de Usuario (Admin vs Usuario)

Por defecto, todo usuario nuevo es `usuario` (solo lectura). Para hacer pruebas de administrador (crear/editar cápsulas):

1.  Regístrate en la app.
2.  Ve a la [Consola de Firebase > Firestore Database > usuarios](https://console.firebase.google.com/).
3.  Busca tu ID de usuario.
4.  Cambia el campo `rol` de `"usuario"` a `"admin"`.
5.  Reinicia la app.

---

## 📦 4. Compilación y Despliegue (Build)

### Generar APK (Android)

Para distribuir la app manualmente (sin Play Store):

```bash
flutter build apk --release
```

*   **Ubicación del archivo:** `build/app/outputs/flutter-apk/app-release.apk`
*   **Nota:** Este APK está firmado con una clave de depuración o la clave configurada en `build.gradle`. Para producción real, configura `key.properties`.

### Renombrar el APK (Opcional)

Si quieres entregar el archivo con un nombre profesional, usa PowerShell después de compilar:

```powershell
Copy-Item "build/app/outputs/flutter-apk/app-release.apk" "NeuroConecta-v1.0.apk"
```

---

## 🔧 5. Solución de Problemas Comunes (Troubleshooting)

### Error: "The query requires an index"
*   **Síntoma:** Los comentarios no cargan o la consola muestra un error de Firestore.
*   **Solución:** Mira los logs en la terminal (`flutter run`). Firebase te dará un enlace URL largo. Haz clic en él, acepta la creación del índice en el navegador y espera 5 minutos.

### Error: "google-services.json missing"
*   **Síntoma:** La app crashea al iniciar.
*   **Solución:** Te falta el archivo de configuración de Firebase en `android/app/`. Ver paso 2.2.

### Error: "CocoaPods not installed" (Solo macOS)
*   **Solución:**
    ```bash
    cd ios
    pod install
    cd ..
    ```

---

## 📂 6. Estructura del Código (Para Desarrolladores)

*   `lib/features/auth`: Lógica de Login/Registro.
*   `lib/features/capsulas`: El corazón de la app. Contiene el CRUD de cápsulas.
*   `lib/features/feedback`: Sistema de comentarios y valoración.
*   `lib/core/theme`: Aquí puedes cambiar los colores (Paleta Lavanda).

---

**Contacto de Soporte:** [Tu Nombre/Correo]
**Repositorio:** [Link a tu GitHub si aplica]
