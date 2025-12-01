import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_theme.dart';
import '../../../../routes/app_routes.dart';
import '../models/capsula.dart';
import '../services/firestore_service.dart';
import '../widgets/capsule_card.dart';
import '../../auth/services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hola, ${_currentUser?.displayName?.split(' ')[0] ?? 'Usuario'}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              'Explora tus cápsulas',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.primaryColor),
            onPressed: () async {
              await _authService.signOut();
              // GoRouter redirige automáticamente
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: StreamBuilder<List<Capsula>>(
          stream: _firestoreService.getCapsulas(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final allCapsulas = snapshot.data ?? [];
            
            // Filtrar: Si NO es admin, ocultar borradores
            final capsulas = _isAdmin 
                ? allCapsulas 
                : allCapsulas.where((c) => !c.esBorrador).toList();

            if (capsulas.isEmpty) {
              return const Center(
                child: Text(
                  'No hay cápsulas disponibles por el momento.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(top: 16, bottom: 80),
              itemCount: capsulas.length,
              itemBuilder: (context, index) {
                return CapsuleCard(capsula: capsulas[index]);
              },
            );
          },
        ),
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton.extended(
              onPressed: () {
                context.push(AppRoutes.createCapsule);
              },
              label: const Text('Nueva Cápsula'),
              icon: const Icon(Icons.add),
              backgroundColor: AppTheme.primaryColor,
            )
          : null,
    );
  }
}

