import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:neuroconecta2/models/guia.dart';
import 'package:neuroconecta2/services/guias_firestore_service.dart';
import 'package:neuroconecta2/services/firestore_service.dart' as fs;

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
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/detalles-guia/${guia.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Text(
            guia.titulo,
            style: Theme.of(context).textTheme.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}