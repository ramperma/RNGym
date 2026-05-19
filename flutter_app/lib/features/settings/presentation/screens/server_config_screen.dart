import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/storage/secure_storage.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ServerConfigScreen extends ConsumerStatefulWidget {
  const ServerConfigScreen({super.key});

  @override
  ConsumerState<ServerConfigScreen> createState() => _ServerConfigScreenState();
}

class _ServerConfigScreenState extends ConsumerState<ServerConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serverController = TextEditingController(text: 'http://');
  final _portController = TextEditingController(text: '8000');
  final _pathController = TextEditingController(text: '/api/v1');

  bool _isTesting = false;
  String? _errorMessage;
  bool _testSuccess = false;

  @override
  void dispose() {
    _serverController.dispose();
    _portController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  Future<void> _testAndSaveConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isTesting = true;
      _errorMessage = null;
      _testSuccess = false;
    });

    String server = _serverController.text.trim();
    String port = _portController.text.trim();
    String path = _pathController.text.trim();

    // Normalizar la URL
    if (!server.startsWith('http://') && !server.startsWith('https://')) {
      server = 'http://$server';
    }
    
    // Quitar barras inclinadas al final
    if (server.endsWith('/')) {
      server = server.substring(0, server.length - 1);
    }

    String fullUrl = server;
    if (port.isNotEmpty) {
      fullUrl = '$fullUrl:$port';
    }
    
    // Asegurar que comience con barra o ruta correcta
    if (!path.startsWith('/')) {
      path = '/$path';
    }
    if (path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }
    
    fullUrl = '$fullUrl$path';

    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
      ));

      // Comprobar la salud del endpoint
      final response = await dio.get('$fullUrl/health');
      
      if (response.statusCode == 200) {
        setState(() {
          _testSuccess = true;
          _isTesting = false;
        });

        // Guardar la URL en el almacenamiento seguro
        final storage = ref.read(secureStorageProvider);
        await storage.saveApiBaseUrl(fullUrl);

        // Actualizar el provider de la API
        ref.read(apiUrlProvider.notifier).state = fullUrl;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1E281E),
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('¡Conexión establecida correctamente! ⚡', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );

        // Redirigir de inmediato al Login
        if (mounted) {
          context.go('/login');
        }
      } else {
        throw Exception('El servidor respondió con código ${response.statusCode}');
      }
    } catch (e) {
      String msg = 'No se pudo conectar al servidor. ';
      if (e is DioException) {
        if (e.type == DioExceptionType.connectionTimeout) {
          msg += 'Tiempo de espera agotado (¿el servidor está encendido?).';
        } else if (e.type == DioExceptionType.connectionError) {
          msg += 'Error de red (verifica la IP o el dominio).';
        } else {
          msg += e.message ?? e.toString();
        }
      } else {
        msg += e.toString();
      }

      setState(() {
        _errorMessage = msg;
        _isTesting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F12),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icono Premium de Servidor
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.08),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.orange.withOpacity(0.2), width: 1.5),
                      ),
                      child: const Icon(
                        Icons.dns_rounded,
                        color: Colors.orange,
                        size: 48,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Título principal
                  const Text(
                    'Servidor de Producción',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),

                  const Text(
                    'Introduce los datos de conexión a tu servidor de Gym Trainer en internet para vincular la aplicación.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white38,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Caja de entrada
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16161E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Dirección IP/Host
                        const Text(
                          'DIRECCIÓN O IP',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange, letterSpacing: 1),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _serverController,
                          style: const TextStyle(color: Colors.white, fontSize: 15),
                          decoration: InputDecoration(
                            hintText: 'ej: gym.pereznet.es o 192.168.1.106',
                            hintStyle: const TextStyle(color: Colors.white12),
                            prefixIcon: const Icon(Icons.link, color: Colors.white24, size: 20),
                            border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
                            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.orange)),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty || value.trim() == 'http://' || value.trim() == 'https://') {
                              return 'Por favor introduce la IP o dirección del servidor';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Puerto y Ruta de la API
                        Row(
                          children: [
                            // Puerto
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'PUERTO',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white38, letterSpacing: 1),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _portController,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(color: Colors.white, fontSize: 15),
                                    decoration: InputDecoration(
                                      hintText: 'ej: 8000',
                                      hintStyle: const TextStyle(color: Colors.white12),
                                      prefixIcon: const Icon(Icons.settings_ethernet, color: Colors.white24, size: 20),
                                      border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
                                      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.orange)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Ruta Base
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'RUTA BASE API',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white38, letterSpacing: 1),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _pathController,
                                    style: const TextStyle(color: Colors.white, fontSize: 15),
                                    decoration: InputDecoration(
                                      hintText: '/api/v1',
                                      hintStyle: const TextStyle(color: Colors.white12),
                                      prefixIcon: const Icon(Icons.folder_open, color: Colors.white24, size: 20),
                                      border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
                                      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.orange)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Mensaje de Error / Éxito
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.redAccent, fontSize: 12, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Botón de Conexión
                  ElevatedButton(
                    onPressed: _isTesting ? null : _testAndSaveConnection,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      shadowColor: Colors.orange.withOpacity(0.3),
                    ),
                    child: _isTesting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text(
                                'Conectar con Servidor de Producción ⚡',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
