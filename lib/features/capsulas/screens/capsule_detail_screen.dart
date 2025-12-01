import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_theme.dart';
import '../../../../routes/app_routes.dart';
import '../models/capsula.dart';
import '../services/firestore_service.dart';
import '../../feedback/widgets/feedback_list.dart';
import '../../feedback/widgets/feedback_form.dart';

class CapsuleDetailScreen extends StatefulWidget {
  final String capsuleId;

  const CapsuleDetailScreen({super.key, required this.capsuleId});

  @override
  State<CapsuleDetailScreen> createState() => _CapsuleDetailScreenState();
}

class _CapsuleDetailScreenState extends State<CapsuleDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  Future<void> _checkRole() async {
    final isAdmin = await _firestoreService.isAdmin();
    if (mounted) {
      setState(() {
        _isAdmin = isAdmin;
      });
    }
  }

  Future<void> _deleteCapsule(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Cápsula'),
        content: const Text('¿Estás seguro? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await _firestoreService.deleteCapsula(widget.capsuleId);
      if (mounted) {
        context.pop(); // Volver al Home
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cápsula eliminada')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Capsula>(
      stream: _firestoreService.getCapsula(widget.capsuleId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: const Center(child: Text('No se pudo cargar la cápsula')),
          );
        }

        final capsula = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: Text(capsula.titulo),
            backgroundColor: AppTheme.backgroundColor,
            actions: _isAdmin
                ? [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        context.push('${AppRoutes.editCapsule}/${capsula.id}');
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteCapsule(context),
                    ),
                  ]
                : null,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Info
                Row(
                  children: [
                    Chip(
                      label: Text(capsula.categoria),
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(capsula.segmento.toUpperCase()),
                      backgroundColor: Colors.grey.shade200,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Contenido Markdown
                MarkdownBody(
                  data: capsula.contenidoLargo,
                  styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                    p: Theme.of(context).textTheme.bodyLarge,
                    h1: Theme.of(context).textTheme.displaySmall,
                    h2: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                
                const SizedBox(height: 32),
                const Divider(thickness: 2),
                const SizedBox(height: 16),

                // Sección de Retroalimentación
                Text(
                  'Comentarios y Valoraciones',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                
                FeedbackForm(capsulaId: capsula.id),
                
                const SizedBox(height: 16),
                
                FeedbackList(capsulaId: capsula.id, isAdmin: _isAdmin),
              ],
            ),
          ),
        );
      },
    );
  }
}

