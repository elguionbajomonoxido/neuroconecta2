import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class PantallaLogin extends StatefulWidget {
  const PantallaLogin({super.key});

  @override
  State<PantallaLogin> createState() => _PantallaLoginState();
}

class _PantallaLoginState extends State<PantallaLogin> {
  final ServicioAutenticacion _servicioAutenticacion = ServicioAutenticacion();
  final _formKey = GlobalKey<FormState>();

  // Controladores
  final TextEditingController _controladorEmail = TextEditingController();
  final TextEditingController _controladorContrasena = TextEditingController();
  final TextEditingController _controladorNombre = TextEditingController();

  bool _estaRegistrando = false;
  bool _estaCargando = false;

  @override
  void dispose() {
    _controladorEmail.dispose();
    _controladorContrasena.dispose();
    _controladorNombre.dispose();
    super.dispose();
  }

  // Validadores
  String? _validarEmail(String? value) {
    if (value == null || value.isEmpty) return 'El correo es obligatorio';
    if (!value.contains('@')) return 'Ingresa un correo válido';
    return null;
  }

  String? _validarContrasena(String? value) {
    if (value == null || value.isEmpty) return 'La contraseña es obligatoria';
    if (value.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }

  String? _validarNombre(String? value) {
    if (!_estaRegistrando) return null;
    if (value == null || value.isEmpty) return 'El nombre es obligatorio';
    return null;
  }

  // Acciones
  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _estaCargando = true;
    });

    try {
      if (_estaRegistrando) {
        // Registro
        await _servicioAutenticacion.registrarseConEmailYContrasena(
          _controladorEmail.text.trim(),
          _controladorContrasena.text.trim(),
          _controladorNombre.text.trim(),
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cuenta creada. ¡Revisa tu correo para verificarla!'),
              backgroundColor: Colors.green,
            ),
          );
          // Volver a modo inicioSesion para que inicien sesión después de verificar
          setState(() {
            _estaRegistrando = false;
          });
        }
      } else {
        // Login
        final credential = await _servicioAutenticacion.iniciarSesionConEmailYContrasena(
          _controladorEmail.text.trim(),
          _controladorContrasena.text.trim(),
        );

        if (credential.user != null && !credential.user!.emailVerified) {
          await _servicioAutenticacion.cerrarSesion(); // No dejar entrar
          if (mounted) {
            _mostrarError('Debes verificar tu correo electrónico antes de entrar.');
          }
        }
        // Si está verificado, el GoRouter redirigirá automáticamente
      }
    } catch (e) {
      if (mounted) {
        _mostrarError(e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() {
          _estaCargando = false;
        });
      }
    }
  }

  Future<void> _iniciarSesionConGoogle() async {
    setState(() {
      _estaCargando = true;
    });

    try {
      await _servicioAutenticacion.iniciarSesionConGoogle();
      // GoRouter redirigirá automáticamente
    } catch (e) {
      if (mounted) {
        _mostrarError(e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() {
          _estaCargando = false;
        });
      }
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo y Título
              Image.asset(
                'assets/icon/app_icon.png',
                width: 80,
                height: 80,
              ),
              const SizedBox(height: 16),
              Text(
                'NeuroConecta',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                _estaRegistrando ? 'Crea tu cuenta' : 'Bienvenido de nuevo',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 32),

              // Formulario
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (_estaRegistrando) ...[
                      TextFormField(
                        controller: _controladorNombre,
                        decoration: const InputDecoration(
                          labelText: 'Nombre completo',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: _validarNombre,
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _controladorEmail,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: _validarEmail,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _controladorContrasena,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: _validarContrasena,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Botón Principal (Login/Registro)
              ElevatedButton(
                onPressed: _estaCargando ? null : _enviar,
                child: _estaCargando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(_estaRegistrando ? 'Registrarse' : 'Iniciar Sesión'),
              ),
              const SizedBox(height: 16),

              // Separador
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('O continúa con'),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),

              // Botón Google
              OutlinedButton.icon(
                onPressed: _estaCargando ? null : _iniciarSesionConGoogle,
                icon: const Icon(Icons.g_mobiledata, size: 28), // Icono simple de Google
                label: const Text('Google'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Toggle Login/Registro
              TextButton(
                onPressed: () {
                  setState(() {
                    _estaRegistrando = !_estaRegistrando;
                    _formKey.currentState?.reset();
                  });
                },
                child: Text(
                  _estaRegistrando
                      ? '¿Ya tienes cuenta? Inicia sesión'
                      : '¿No tienes cuenta? Regístrate',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
