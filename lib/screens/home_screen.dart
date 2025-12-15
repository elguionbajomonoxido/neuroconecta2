import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../routes/app_routes.dart';
import '../models/capsula.dart';
import '../services/firestore_service.dart';
import '../services/feedback_service.dart';
import '../widgets/capsula_card.dart';
import '../controllers/settings_controller.dart';

class PaginaInicio extends StatefulWidget {
  const PaginaInicio({super.key});

  @override
  State<PaginaInicio> createState() => _PaginaInicioState();
}

class _PaginaInicioState extends State<PaginaInicio> {
  final ServicioFirestore _servicioFirestore = ServicioFirestore();
  final ServicioRetroalimentacion _servicioRetro = ServicioRetroalimentacion();
  final User? _usuarioActual = FirebaseAuth.instance.currentUser;
  
  bool _esAdmin = false;
  String _ordenSeleccionado = 'mas_reciente';
  String? _autorFiltro;
  Map<String, double> _promedios = {};
  bool _estaCargandoPromedios = false;

  Future<void> _cargarPromedios() async {
    if (_estaCargandoPromedios) return;
    setState(() => _estaCargandoPromedios = true);
    try {
      final proms = await _servicioRetro.obtenerPromediosPorCapsulas();
      if (mounted) setState(() => _promedios = proms);
    } catch (_) {
      // Silencioso: si falla, dejamos el mapa vacío (0.0 por defecto al ordenar)
    } finally {
      if (mounted) setState(() => _estaCargandoPromedios = false);
    }
  }

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

            // Aplicar filtro por autor si está seleccionado
            final listaPorAutor = (_autorFiltro == null || _autorFiltro == 'Todos')
                ? capsulasFiltradas
                : capsulasFiltradas.where((c) => c.autor == _autorFiltro).toList();

            // Obtener lista de autores para dropdown
            final autoresSet = <String>{};
            for (final c in todasCapsulas) {
              if ((c.autor).isNotEmpty) autoresSet.add(c.autor);
            }
            final autores = ['Todos', ...autoresSet.toList()];

            Widget listaOrdenadaWidget(List<Capsula> lista) {
              // Ordenamientos simples
              switch (_ordenSeleccionado) {
                case 'A_to_Z':
                  lista.sort((a, b) => a.titulo.toLowerCase().compareTo(b.titulo.toLowerCase()));
                  break;
                case 'Z_to_A':
                  lista.sort((a, b) => b.titulo.toLowerCase().compareTo(a.titulo.toLowerCase()));
                  break;
                case 'mas_reciente':
                  lista.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                  break;
                case 'mas_antigua':
                  lista.sort((a, b) => a.createdAt.compareTo(b.createdAt));
                  break;
                default:
                  break;
              }

              return ListView.builder(
                padding: const EdgeInsets.only(top: 16, bottom: 80),
                itemCount: lista.length,
                itemBuilder: (context, index) {
                  return TarjetaCapsula(capsula: lista[index]);
                },
              );
            }

            if (capsulasFiltradas.isEmpty) {
              return const Center(
                child: Text(
                  'No hay cápsulas disponibles por el momento.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              );
            }

            // Cabecera de filtros: orden + autor
            return Column(
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Botón de orden (compacto y escalable)
                    Flexible(
                      fit: FlexFit.loose,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: PopupMenuButton<String>(
                          initialValue: _ordenSeleccionado,
                          onSelected: (val) async {
                            setState(() => _ordenSeleccionado = val);
                            if (val == 'relevancia') {
                              if (_promedios.isEmpty) await _cargarPromedios();
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
                              color: tema.colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.sort_outlined),
                                const SizedBox(width: 8),
                                Text('Orden'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Dropdown de autores con etiqueta y expandible para evitar overflow
                    Expanded(
                      child: Row(
                        children: [
                          Text('Autores:', style: tema.textTheme.bodyMedium),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _autorFiltro ?? 'Todos',
                              items: autores.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                              onChanged: (val) => setState(() => _autorFiltro = val),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Expanded con contenido que depende del orden seleccionado
                Expanded(
                  child: _ordenSeleccionado == 'relevancia'
                      ? (_estaCargandoPromedios
                          ? const Center(child: CircularProgressIndicator())
                          : (_promedios.isEmpty
                              ? Center(
                                  child: ElevatedButton(
                                    onPressed: _cargarPromedios,
                                    child: const Text('Cargar relevancia'),
                                  ),
                                )
                              : listaOrdenadaWidget(List<Capsula>.from(listaPorAutor)..sort((a, b) {
                                  final pa = _promedios[a.id] ?? 0.0;
                                  final pb = _promedios[b.id] ?? 0.0;
                                  return pb.compareTo(pa);
                                }))))
                      : listaOrdenadaWidget(List<Capsula>.from(listaPorAutor)),
                ),
              ],
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

