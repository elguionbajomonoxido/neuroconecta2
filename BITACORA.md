# Bitácora de Desarrollo - NeuroConecta 📝

**Estudiante:** [Tu Nombre]
**Asignatura:** Desarrollo de Aplicaciones Móviles
**Fecha de Inicio:** 01/12/2025

| Fecha | Tareas Realizadas | Competencias Desarrolladas | Indicadores Cubiertos | Dificultades Encontradas | Soluciones / Estrategias |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 01/12/2025 | Configuración inicial del proyecto Flutter y estructura de carpetas. | Arquitectura de Software, Configuración de Entornos. | Estructura de proyecto limpia y escalable. | Conflictos de versiones en `pubspec.yaml`. | Se ajustaron las versiones de `firebase_core` y `flutter_lints` a compatibles. |
| 01/12/2025 | Integración de Firebase (Auth y Firestore). | Backend-as-a-Service (BaaS), Autenticación. | Conexión exitosa con servicios en la nube. | Configuración del SHA-1 para Google Sign-In. | Se generó el SHA-1 usando `./gradlew signingReport` y se agregó a la consola de Firebase. |
| 01/12/2025 | Implementación de Login y Registro con validaciones. | UI/UX, Manejo de Formularios, Gestión de Estado. | Autenticación segura y validación de datos. | Manejo de estados de carga y errores asíncronos. | Uso de `setState` y bloques `try-catch` para feedback visual al usuario. |
| 01/12/2025 | Desarrollo del CRUD de Cápsulas (Crear, Leer, Actualizar). | Manipulación de Datos, Lógica de Negocio. | Operaciones CRUD completas en base de datos NoSQL. | Filtrado de datos por rol de usuario en tiempo real. | Implementación de lógica en `FirestoreService` y renderizado condicional en la UI. |
| 01/12/2025 | Sistema de Retroalimentación (Estrellas y Comentarios). | Interacción Usuario-Sistema, Modelado de Datos. | Participación del usuario y persistencia de datos relacionales. | Actualización en tiempo real de la lista de comentarios. | Uso de `StreamBuilder` para escuchar cambios en la colección `retroalimentaciones`. |
| 01/12/2025 | Pruebas finales, generación de APK y documentación. | Despliegue, Documentación Técnica. | Entrega de producto funcional y documentado. | Ajustes finales de diseño responsive. | Revisión de `Overflow` en pantallas pequeñas y uso de `SingleChildScrollView`. |

---
**Conclusiones Generales:**
El desarrollo de NeuroConecta permitió consolidar conocimientos sobre la integración de Flutter con servicios en la nube. La arquitectura por features facilitó el desarrollo modular, permitiendo implementar funcionalidades complejas como la autenticación y el CRUD de manera ordenada. Se cumplieron todos los requerimientos funcionales y de seguridad solicitados.
