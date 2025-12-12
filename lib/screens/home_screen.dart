import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../routes/app_routes.dart';
import '../models/capsula.dart';
import '../services/firestore_service.dart';
import '../widgets/capsula_card.dart';
import '../controllers/settings_controller.dart';

class PaginaInicio extends StatefulWidget {
  const PaginaInicio({super.key});

  @override
  State<PaginaInicio> createState() => _PaginaInicioState();
}

class _PaginaInicioState extends State<PaginaInicio> {
  final ServicioFirestore _servicioFirestore = ServicioFirestore();
  final User? _usuarioActual = FirebaseAuth.instance.currentUser;
  
  bool _esAdmin = false;

  @override
  void initState() {
    super.initState();
    _verificarRol();
  }

  Future<void> _verificarRol() async {
    final esAdmin = await _servicioFirestore.esAdmin();
    if (mounted) {
      setState(() {
        _esAdmin = esAdmin;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final configuracion = Provider.of<ControladorConfiguracion>(context);
    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: tema.colorScheme.surface,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hola, ${_usuarioActual?.displayName?.split(' ')[0] ?? 'Usuario'}',
              style: tema.textTheme.titleLarge,
            ),
            Text(
              'Explora tus cápsulas',
              style: tema.textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: tema.colorScheme.primary),
            onPressed: () => context.push(RutasAplicacion.configuracion),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: StreamBuilder<List<Capsula>>(
          stream: _servicioFirestore.obtenerCapsulas(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final todasCapsulas = snapshot.data ?? [];
            
            // Filtrar: Si NO es admin, ocultar borradores
            // Filtrar: Si Kids Mode está activo, solo mostrar segmento 'niños'
            final capsulasFiltradas = todasCapsulas.where((c) {
              if (!_esAdmin && c.esBorrador) return false;
              if (configuracion.modoNinosActivado && c.segmento != 'niños') return false;
              return true;
            }).toList();

            if (capsulasFiltradas.isEmpty) {
              return const Center(
                child: Text(
                  'No hay cápsulas disponibles por el momento.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(top: 16, bottom: 80),
              itemCount: capsulasFiltradas.length,
              itemBuilder: (context, index) {
                return TarjetaCapsula(capsula: capsulasFiltradas[index]);
              },
            );
          },
        ),
      ),
      floatingActionButton: _esAdmin
          ? FloatingActionButton.extended(
              onPressed: () {
                context.push(RutasAplicacion.crearCapsula);
              },
              label: const Text('Nueva Cápsula'),
              icon: const Icon(Icons.add),
              backgroundColor: tema.colorScheme.primary,
            )
          : null,
    );
  }
}

