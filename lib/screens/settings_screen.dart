import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/settings_controller.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'editar_groserias_screen.dart';
import 'package:go_router/go_router.dart';
import '../routes/app_routes.dart';

class PaginaConfiguracion extends StatefulWidget {
  const PaginaConfiguracion({super.key});

  @override
  State<PaginaConfiguracion> createState() => _PaginaConfiguracionState();
}

class _PaginaConfiguracionState extends State<PaginaConfiguracion> {
  final ServicioAutenticacion _servicioAutenticacion = ServicioAutenticacion();
  final User? _usuarioActual = FirebaseAuth.instance.currentUser;
  final TextEditingController _controladorNombre = TextEditingController();
  bool _esAdmin = false;

  @override
  void initState() {
    super.initState();
    _controladorNombre.text = _usuarioActual?.displayName ?? '';
    _verificarAdmin();
  }

  Future<void> _verificarAdmin() async {
    try {
      final servicio = ServicioFirestore();
      final es = await servicio.esAdmin();
      if (!mounted) return;
      setState(() => _esAdmin = es);
    } catch (_) {
      // ignore
    }
  }

  @override
  void dispose() {
    _controladorNombre.dispose();
    super.dispose();
  }

  // --- Lógica de Perfil ---

  // --- CAMBIAR CONTRASEÑA ---
  void _showChangePasswordDialog() {
    final currentPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        bool currentPassVisible = false;
        bool newPassVisible = false;
        bool confirmPassVisible = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Cambiar Contraseña'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: currentPassController,
                      decoration: InputDecoration(
                        labelText: 'Contraseña Actual',
                        suffixIcon: IconButton(
                          icon: Icon(currentPassVisible ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => currentPassVisible = !currentPassVisible),
                        ),
                      ),
                      obscureText: !currentPassVisible,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: newPassController,
                      decoration: InputDecoration(
                        labelText: 'Nueva Contraseña',
                        suffixIcon: IconButton(
                          icon: Icon(newPassVisible ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => newPassVisible = !newPassVisible),
                        ),
                      ),
                      obscureText: !newPassVisible,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: confirmPassController,
                      decoration: InputDecoration(
                        labelText: 'Confirmar Nueva Contraseña',
                        suffixIcon: IconButton(
                          icon: Icon(confirmPassVisible ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => confirmPassVisible = !confirmPassVisible),
                        ),
                      ),
                      obscureText: !confirmPassVisible,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () async {
                    if (newPassController.text != confirmPassController.text) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Las nuevas contraseñas no coinciden')),
                      );
                      return;
                    }
                    if (newPassController.text.length < 6) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('La contraseña debe tener al menos 6 caracteres')),
                      );
                      return;
                    }

                    try {
                      // Mostrar indicador de carga
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (c) => const Center(child: CircularProgressIndicator()),
                      );

                      await _servicioAutenticacion.cambiarContrasena(
                        currentPassController.text,
                        newPassController.text,
                      );

                      if (mounted) {
                        Navigator.pop(context); // Cerrar loading
                        Navigator.pop(context); // Cerrar diálogo de cambio
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Contraseña actualizada correctamente')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        Navigator.pop(context); // Cerrar loading
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  child: const Text('Actualizar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- CAMBIAR CORREO ---
  void _showChangeEmailDialog() {
    final currentPassController = TextEditingController();
    final newEmailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        bool currentPassVisible = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Cambiar Correo Electrónico'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Necesitamos verificar tu identidad para cambiar el correo.'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: currentPassController,
                    decoration: InputDecoration(
                      labelText: 'Contraseña Actual',
                      suffixIcon: IconButton(
                        icon: Icon(currentPassVisible ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => currentPassVisible = !currentPassVisible),
                      ),
                    ),
                    obscureText: !currentPassVisible,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: newEmailController,
                    decoration: const InputDecoration(labelText: 'Nuevo Correo'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () async {
                    if (newEmailController.text.isEmpty || currentPassController.text.isEmpty) return;

                    try {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (c) => const Center(child: CircularProgressIndicator()),
                      );

                      await _servicioAutenticacion.cambiarEmail(
                        currentPassController.text,
                        newEmailController.text.trim(),
                      );

                      if (mounted) {
                        Navigator.pop(context); // Cerrar loading
                        Navigator.pop(context); // Cerrar diálogo
                        
                        // Mostrar mensaje explicativo importante
                        showDialog(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: const Text('Verificación Enviada'),
                            content: Text(
                              'Se ha enviado un correo de verificación a ${newEmailController.text}. '
                              'Debes confirmar el cambio en ese enlace para que se actualice tu cuenta.'
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(c), child: const Text('Entendido'))
                            ],
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        Navigator.pop(context); // Cerrar loading
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  child: const Text('Actualizar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _actualizarNombreUsuario() async {
    final user = _usuarioActual;
    if (user == null) return;

    final String nuevoNombre = _controladorNombre.text.trim();
    if (nuevoNombre.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre debe tener al menos 2 caracteres')),
      );
      return;
    }

    try {
      await user.updateDisplayName(nuevoNombre);
      await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).update({
        'nombre': nuevoNombre,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nombre actualizado correctamente')),
        );
        FocusScope.of(context).unfocus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar nombre: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final configuracion = Provider.of<ControladorConfiguracion>(context);
    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: tema.colorScheme.surface,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- Sección Apariencia ---
          _construirEncabezadoSeccion(context, 'Apariencia y Accesibilidad'),
          
          ListTile(
            title: const Text('Paleta de Colores'),
            subtitle: Text(_obtenerNombrePaleta(configuracion.paletaTema)),
            trailing: DropdownButton<String>(
              value: configuracion.paletaTema,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'lavanda', child: Text('Lavanda')),
                DropdownMenuItem(value: 'azul_calma', child: Text('Azul')),
                DropdownMenuItem(value: 'verde_esperanza', child: Text('Verde')),
                DropdownMenuItem(value: 'rojo_pasion', child: Text('Rojo')),
                DropdownMenuItem(value: 'naranja_vital', child: Text('Naranja')),
                DropdownMenuItem(value: 'rosa_suave', child: Text('Rosa')),
              ],
              onChanged: (val) {
                if (val != null) configuracion.establecerPaletaTema(val);
              },
            ),
          ),

          ListTile(
            title: const Text('Modo Daltónico'),
            subtitle: Text(_obtenerNombreModoDaltonico(configuracion.modoDaltonismo)),
            trailing: DropdownButton<String>(
              value: configuracion.modoDaltonismo,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'none', child: Text('Ninguno')),
                DropdownMenuItem(value: 'deuteranopia', child: Text('Deuteranopia')),
                DropdownMenuItem(value: 'protanopia', child: Text('Protanopia')),
                DropdownMenuItem(value: 'tritanopia', child: Text('Tritanopia')),
              ],
              onChanged: (val) {
                if (val != null) configuracion.establecerModoDaltonismo(val);
              },
            ),
          ),

          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tamaño de Texto: ${(configuracion.factorEscalaTexto * 100).toInt()}%', style: tema.textTheme.bodyMedium),
                Slider(
                  value: configuracion.factorEscalaTexto,
                  min: 0.8,
                  max: 1.5,
                  divisions: 7,
                  label: configuracion.factorEscalaTexto.toStringAsFixed(1),
                  onChanged: (val) => configuracion.establecerFactorEscalaTexto(val),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: tema.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Así se verá el texto en la aplicación. Ajusta el tamaño según tus necesidades.',
                    style: tema.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 32),

          // --- Sección Contenido ---
          _construirEncabezadoSeccion(context, 'Contenido'),
          SwitchListTile(
            title: const Text('Modo Niños'),
            subtitle: const Text('Mostrar solo cápsulas aptas para niños'),
            value: configuracion.modoNinosActivado,
            onChanged: (val) => configuracion.establecerModoNinos(val),
            activeThumbColor: tema.colorScheme.primary,
          ),

          // Opción para administrar lista de groserías (solo admins)
          if (_esAdmin) ListTile(
            leading: const Icon(Icons.shield_moon_outlined),
            title: const Text('Editar lista de groserías'),
            subtitle: const Text('Solo disponible para administradores'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const EditarGroseriasScreen()));
            },
          ),

          const Divider(height: 32),

          // --- Sección Perfil ---
          _construirEncabezadoSeccion(context, 'Perfil'),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _controladorNombre,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de usuario',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _actualizarNombreUsuario,
                icon: const Icon(Icons.save),
                tooltip: 'Guardar nombre',
                style: IconButton.styleFrom(
                  backgroundColor: tema.colorScheme.primaryContainer,
                  foregroundColor: tema.colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),

          const Divider(height: 32),

          // --- Sección Seguridad (Solo para usuarios con Email/Password) ---
          if (_usuarioActual?.providerData.any((p) => p.providerId == 'password') ?? false) ...[
            _construirEncabezadoSeccion(context, 'Seguridad'),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Cambiar Contraseña'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _showChangePasswordDialog,
            ),
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text('Cambiar Correo Electrónico'),
              subtitle: Text(_usuarioActual?.email ?? ''),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _showChangeEmailDialog,
            ),
            const Divider(height: 32),
          ],

          // --- Sección Cuenta ---
          _construirEncabezadoSeccion(context, 'Cuenta'),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('¿Cerrar sesión?'),
                  content: const Text('Tendrás que volver a ingresar tus credenciales.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Salir')),
                  ],
                ),
              );

              if (confirm == true) {
                // Marcar que estamos cerrando sesión para evitar redirecciones automáticas
                RutasAplicacion.isLoggingOut = true;
                
                await _servicioAutenticacion.cerrarSesion();
                if (mounted) context.go(RutasAplicacion.inicioSesion);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _construirEncabezadoSeccion(BuildContext context, String titulo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        titulo,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _obtenerNombrePaleta(String palette) {
    switch (palette) {
      case 'lavanda': return 'Lavanda Suave';
      case 'azul_calma': return 'Azul Calma';
      case 'verde_esperanza': return 'Verde Esperanza';
      case 'rojo_pasion': return 'Rojo Pasión';
      case 'naranja_vital': return 'Naranja Vital';
      case 'rosa_suave': return 'Rosa Suave';
      default: return 'Lavanda Suave';
    }
  }

  String _obtenerNombreModoDaltonico(String mode) {
    switch (mode) {
      case 'deuteranopia': return 'Deuteranopia (Rojo/Verde)';
      case 'protanopia': return 'Protanopia (Rojo intenso)';
      case 'tritanopia': return 'Tritanopia (Azul/Amarillo)';
      default: return 'Ninguno';
    }
  }
}
