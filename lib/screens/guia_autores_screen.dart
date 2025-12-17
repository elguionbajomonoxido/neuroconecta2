import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:neuroconecta2/models/guia.dart';
import 'package:neuroconecta2/services/guias_firestore_service.dart';
import 'package:neuroconecta2/services/firestore_service.dart' as fs;
import 'package:neuroconecta2/widgets/adaptive_image.dart';

class GuiaAutoresScreen extends StatelessWidget {
  // ID de la guía principal que sirve como ejemplo
  static const String guiaEjemploId = 'tutorial-markdown-autores';

  const GuiaAutoresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = fs.ServicioFirestore();
    final guiasService = GuiasFirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Guía para Autores'),
        elevation: 0,
      ),
      body: FutureBuilder<bool>(
        future: _verificarAcceso(firestoreService),
        builder: (context, authSnapshot) {
          if (authSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (authSnapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Error al verificar acceso'),
                  const SizedBox(height: 8),
                  Text(
                    authSnapshot.error.toString(),
                    style: const TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Volver'),
                  ),
                ],
              ),
            );
          }

          if (!(authSnapshot.data ?? false)) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline, size: 64),
                  const SizedBox(height: 16),
                  const Text('Esta guía solo está disponible para autores y admins'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Volver'),
                  ),
                ],
              ),
            );
          }

          // Cargar guías para autores desde colección guias
          return StreamBuilder<List<Guia>>(
            stream: guiasService.obtenerGuiasPorTipo('autores'),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: ${snapshot.error}'),
                    ],
                  ),
                );
              }

              final guias = snapshot.data ?? const <Guia>[];
              if (guias.isEmpty) {
                // Fallback: si el documento ejemplo existe pero no tiene tipoGuia='autores', muéstralo igual.
                return StreamBuilder<Guia?>(
                  stream: guiasService.obtenerGuia(guiaEjemploId),
                  builder: (context, guiaSnapshot) {
                    if (guiaSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final guiaEjemplo = guiaSnapshot.data;
                    if (guiaEjemplo != null) {
                      return ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _construirTarjetaGuia(context, guiaEjemplo),
                        ],
                      );
                    }

                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.info_outline, size: 64),
                          const SizedBox(height: 16),
                          const Text('No hay guías para autores'),
                          const SizedBox(height: 16),
                          const Text(
                            'Crea una guía con tipoGuia = "autores"\n(o la guía ejemplo con ID: $guiaEjemploId)',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Volver'),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }

              // Prioriza la guía ejemplo si existe
              guias.sort((a, b) {
                if (a.id == guiaEjemploId) return -1;
                if (b.id == guiaEjemploId) return 1;
                return b.createdAt.compareTo(a.createdAt);
              });

              return ListView(
                padding: const EdgeInsets.all(16),
                children: guias.map((guia) => _construirTarjetaGuia(context, guia)).toList(),
              );
            },
          );
        },
      ),
    );
  }
  /// Verifica acceso con logs de debug
  Future<bool> _verificarAcceso(fs.ServicioFirestore firestoreService) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      debugPrint(
        '[GuiaAutoresScreen] Usuario actual: ${user?.uid} (${user?.email})',
      );

      final esAdmin = await firestoreService.esAdmin();
      final esAutor = await firestoreService.esAutor();
      debugPrint('[GuiaAutoresScreen] esAdmin: $esAdmin, esAutor: $esAutor');

      final resultado = await firestoreService.esAdminOAutor();
      debugPrint('[GuiaAutoresScreen] esAdminOAutor: $resultado');

      return resultado;
    } catch (e) {
      debugPrint('[GuiaAutoresScreen] Error en verificarAcceso: $e');
      rethrow;
    }
  }

  Widget _construirTarjetaGuia(BuildContext context, Guia guia) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => context.push('/detalles-guia/${guia.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(guia.titulo, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Actualizado: ${guia.updatedAt?.toString().split('.')[0] ?? guia.createdAt.toString().split('.')[0]}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
            if (guia.bloques.isNotEmpty)
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: guia.bloques.take(3).map((bloque) {
                    if (bloque.tipo == 'imagen' && bloque.url != null && bloque.url!.isNotEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: AdaptiveImage(
                            imageUrl: bloque.url!,
                            fit: BoxFit.cover,
                            width: 120,
                            height: 120,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }).toList(),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () => context.push('/detalles-guia/${guia.id}'),
                child: const Text('Ver detalles'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
