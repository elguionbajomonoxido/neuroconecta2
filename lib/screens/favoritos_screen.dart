import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../routes/app_routes.dart';
import '../models/capsula.dart';
import '../services/firestore_service.dart';
import '../services/feedback_service.dart';
import '../widgets/capsula_card.dart';
import '../controllers/favoritos_controller.dart';

class PantallaFavoritos extends StatefulWidget {
  const PantallaFavoritos({super.key});

  @override
  State<PantallaFavoritos> createState() => _PantallaFavoritosState();
}

class _PantallaFavoritosState extends State<PantallaFavoritos> {
  final ServicioFirestore _servicioFirestore = ServicioFirestore();
  final ServicioRetroalimentacion _servicioRetro = ServicioRetroalimentacion();

  bool _esAdmin = false;
  bool _esAutor = false;
  String _ordenSeleccionado = 'A_to_Z';
  Map<String, double> _promedios = {};
  bool _estaCargandoPromedios = false;
  bool _promediosCargados = false;
  bool _sincronizandoFavoritos = false;
  static const String _prefsKeyOrden = 'favoritos_orden_seleccion';

  Future<void> _guardarOrdenSeleccionado(String orden) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKeyOrden, orden);
    } catch (_) {}
  }

  Future<void> _cargarOrdenGuardado() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final orden = prefs.getString(_prefsKeyOrden);
      if (orden != null && mounted) {
        setState(() => _ordenSeleccionado = orden);
        if (orden == 'relevancia') await _cargarPromedios();
      }
    } catch (_) {}
  }

  Future<void> _cargarPromedios([List<String>? capsulaIds]) async {
    if (_estaCargandoPromedios) return;
    setState(() => _estaCargandoPromedios = true);
    try {
      final proms = await _servicioRetro.obtenerPromediosPorCapsulas();
      final Map<String, double> resultado = Map<String, double>.from(proms);

      if (capsulaIds != null) {
        for (final id in capsulaIds) {
          if (!resultado.containsKey(id)) {
            try {
              if (proms.isEmpty) {
                final stats = await _servicioRetro.obtenerEstadisticasCapsula(id);
                final avg = (stats['avg'] as num?)?.toDouble() ?? 0.0;
                resultado[id] = avg;
              } else {
                resultado[id] = 0.0;
              }
            } catch (_) {
              resultado[id] = 0.0;
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _promedios = resultado;
          _promediosCargados = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _promediosCargados = true);
    } finally {
      if (mounted) setState(() => _estaCargandoPromedios = false);
    }
  }

  Future<void> _verificarRoles() async {
    try {
      final esAdmin = await _servicioFirestore.esAdmin();
      final esAutor = await _servicioFirestore.esAutor();

      if (mounted) {
        setState(() {
          _esAdmin = esAdmin;
          _esAutor = esAutor;
        });
      }
    } catch (_) {}
  }

  Widget _buildListaOrdenada(List<Capsula> lista, FavoritosController favController) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, bottom: 80),
      itemCount: lista.length,
      itemBuilder: (context, index) {
        final capsula = lista[index];
        return _CorazonToggle(
          capsula: capsula,
          favController: favController,
          onCardTap: () {},
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _verificarRoles();
    _cargarOrdenGuardado();
    // Sincronizar favoritos desde Firestore al abrir la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sincronizarFavoritos();
    });
  }

  Future<void> _sincronizarFavoritos() async {
    if (_sincronizandoFavoritos) return;
    final favController = Provider.of<FavoritosController>(context, listen: false);
    if (favController.isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sin conexión. Conéctate a internet para continuar.')),
      );
      return;
    }
    setState(() => _sincronizandoFavoritos = true);
    try {
      await favController.syncFromFirestore();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al sincronizar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sincronizandoFavoritos = false);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final favController = context.watch<FavoritosController>();
    final offline = favController.isOffline;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: tema.colorScheme.surface,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mis Favoritos',
              style: tema.textTheme.titleLarge,
            ),
            Text(
              'Tus cápsulas guardadas',
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
        child: Column(
          children: [
            if (offline)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(top: 8, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.wifi_off, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(child: Text('Sin conexión. Conéctate a internet para continuar.')),
                  ],
                ),
              ),
            Expanded(
              child: StreamBuilder<List<Capsula>>(
                stream: _servicioFirestore.obtenerCapsulas(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
                          const SizedBox(height: 16),
                          Text('Error: ${snapshot.error}'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => setState(() {}),
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    );
                  }

                  final todasCapsulas = snapshot.data ?? [];
                  
                  // Filtrar solo cápsulas favoritas según el controller
                  final capsulasFavoritas = todasCapsulas
                      .where((capsula) => favController.isFavorite(capsula.id))
                      .toList();

                  // Ordenar
                  switch (_ordenSeleccionado) {
                    case 'Z_to_A':
                      capsulasFavoritas.sort((a, b) => b.titulo.compareTo(a.titulo));
                      break;
                    case 'relevancia':
                      capsulasFavoritas.sort((a, b) {
                        final pa = _promedios[a.id] ?? 0.0;
                        final pb = _promedios[b.id] ?? 0.0;
                        return pb.compareTo(pa);
                      });
                      break;
                    case 'mas_reciente':
                      capsulasFavoritas.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                      break;
                    case 'mas_antigua':
                      capsulasFavoritas.sort((a, b) => a.createdAt.compareTo(b.createdAt));
                      break;
                    case 'A_to_Z':
                    default:
                      capsulasFavoritas.sort((a, b) => a.titulo.compareTo(b.titulo));
                      break;
                  }

                  // Si no hay favoritos
                  if (capsulasFavoritas.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: _sincronizarFavoritos,
                      child: ListView(
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.favorite_border, size: 64, color: Colors.grey.shade400),
                                const SizedBox(height: 24),
                                Text(
                                  'Aún no tienes favoritos',
                                  style: tema.textTheme.titleLarge?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Marca tus cápsulas favoritas desde el Inicio',
                                  style: tema.textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey.shade500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 32),
                                ElevatedButton.icon(
                                  onPressed: () => context.pop(),
                                  icon: const Icon(Icons.home),
                                  label: const Text('Ir al Inicio'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Con favoritos: mostrar lista con RefreshIndicator
                  return Column(
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Flexible(
                            fit: FlexFit.loose,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: PopupMenuButton<String>(
                                initialValue: _ordenSeleccionado,
                                onSelected: (val) async {
                                  setState(() => _ordenSeleccionado = val);
                                  await _guardarOrdenSeleccionado(val);
                                  if (val == 'relevancia' && !_promediosCargados) {
                                    await _cargarPromedios(capsulasFavoritas.map((c) => c.id).toList());
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(value: 'A_to_Z', child: Text('A → Z')),
                                  const PopupMenuItem(value: 'Z_to_A', child: Text('Z → A')),
                                  const PopupMenuItem(value: 'relevancia', child: Text('Relevancia')),
                                  const PopupMenuItem(value: 'mas_reciente', child: Text('Más reciente')),
                                  const PopupMenuItem(value: 'mas_antigua', child: Text('Más antigua')),
                                ],
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.sort, color: tema.colorScheme.primary, size: 20),
                                      const SizedBox(width: 4),
                                      const Text('Orden'),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _sincronizarFavoritos,
                          child: _ordenSeleccionado == 'relevancia'
                              ? FutureBuilder<void>(
                                  future: !_promediosCargados
                                      ? _cargarPromedios(capsulasFavoritas.map((c) => c.id).toList())
                                      : Future.value(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting || _estaCargandoPromedios) {
                                      return const Center(child: CircularProgressIndicator());
                                    }
                                    return _buildListaOrdenada(capsulasFavoritas, favController);
                                  },
                                )
                              : _buildListaOrdenada(capsulasFavoritas, favController),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: (_esAdmin || _esAutor)
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

/// Widget que separa el toggle del corazón para evitar rebuilds de toda la card
class _CorazonToggle extends StatelessWidget {
  final Capsula capsula;
  final FavoritosController favController;
  final VoidCallback onCardTap;

  const _CorazonToggle({
    required this.capsula,
    required this.favController,
    required this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<FavoritosController, bool>(
      selector: (_, favCtrl) => favCtrl.isFavorite(capsula.id),
      builder: (context, esFavorita, _) {
        return TarjetaCapsula(
          key: ValueKey(capsula.id),
          capsula: capsula,
          esFavorita: esFavorita,
          onToggleFavorito: () {
            final ctx = context;
            if (favController.isOffline) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('Sin conexión. Conéctate a internet para continuar.')),
              );
              return;
            }
            // Cambio local inmediato (optimistic UI)
            favController.toggleLocal(capsula.id);

            // Persistencia en background sin esperar
            favController.persistirToggle(capsula.id).catchError((e) {
              // ignore: use_build_context_synchronously
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(content: Text('Error al actualizar: $e')),
              );
              // Revertir cambio local si falla
              favController.toggleLocal(capsula.id);
            });
          },
        );
      },
    );
  }
}
