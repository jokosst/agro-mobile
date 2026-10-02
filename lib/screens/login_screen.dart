import 'package:flutter/material.dart';
import '../constants/theme.dart';
import '../services/api_service.dart';
import 'main_navigation_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Username dan password wajib diisi.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await ApiService().login(username, password);

    setState(() => _isLoading = false);

    if (res['success'] == true) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    } else {
      setState(() {
        _errorMessage = res['message'] ?? 'Login gagal. Cek username dan password.';
      });
    }
  }

  void _showServerSettings() {
    final controller = TextEditingController(text: ApiService().serverHost);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isPublic = controller.text.trim().contains('itpos.my.id');
          final isLocal = controller.text.trim().contains('agro.test');

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.dns_rounded, color: AgriColors.primary),
                SizedBox(width: 10),
                Text('Pengaturan Server', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pilih server yang ingin digunakan:',
                    style: TextStyle(fontSize: 12, color: AgriColors.textMuted),
                  ),
                  const SizedBox(height: 12),

                  // Preset 1: Server Publis
                  InkWell(
                    onTap: () {
                      setDialogState(() {
                        controller.text = ApiService.publicHost;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isPublic ? AgriColors.primarySubtle : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isPublic ? AgriColors.primary : Colors.grey.shade300,
                          width: isPublic ? 1.8 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.cloud_done_rounded, color: isPublic ? AgriColors.primary : Colors.grey.shade600, size: 24),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Server Publis (Online)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AgriColors.textDark)),
                                SizedBox(height: 2),
                                Text(ApiService.publicHost, style: TextStyle(fontSize: 11, color: AgriColors.textMuted)),
                              ],
                            ),
                          ),
                          if (isPublic)
                            const Icon(Icons.check_circle, color: AgriColors.primary, size: 20),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Preset 2: Server Lokal Valet
                  InkWell(
                    onTap: () {
                      setDialogState(() {
                        controller.text = ApiService.localValetHost;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isLocal ? AgriColors.primarySubtle : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isLocal ? AgriColors.primary : Colors.grey.shade300,
                          width: isLocal ? 1.8 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.laptop_mac_rounded, color: isLocal ? AgriColors.primary : Colors.grey.shade600, size: 24),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Server Lokal (Mac Valet)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AgriColors.textDark)),
                                SizedBox(height: 2),
                                Text(ApiService.localValetHost, style: TextStyle(fontSize: 11, color: AgriColors.textMuted)),
                              ],
                            ),
                          ),
                          if (isLocal)
                            const Icon(Icons.check_circle, color: AgriColors.primary, size: 20),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Text('Atau masukkan alamat kustom:', style: TextStyle(fontSize: 12, color: AgriColors.textMuted)),
                  const SizedBox(height: 8),

                  TextField(
                    controller: controller,
                    onChanged: (_) => setDialogState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Alamat Tujuan Aplikasi',
                      hintText: 'https://itpos.my.id/agro',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      prefixIcon: Icon(Icons.link_rounded),
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AgriColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final nav = Navigator.of(ctx);
                  await ApiService().setServerHost(controller.text.trim());
                  nav.pop();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Server berhasil diatur: ${ApiService().serverHost}'),
                      backgroundColor: AgriColors.primary,
                    ),
                  );
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Background Gambar Kebun Cabai
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_kebun.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // 2. Gradient overlay agar kontras teks branding & form optimal
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.black.withValues(alpha: 0.20),
                    Colors.black.withValues(alpha: 0.55),
                    Colors.black.withValues(alpha: 0.80),
                  ],
                  stops: const [0.0, 0.35, 0.70, 1.0],
                ),
              ),
            ),
          ),

          // 3. Konten Login
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Logo AGROCOM (Storyboard Screen 1)
                    Container(
                      width: 95,
                      height: 95,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Image.asset(
                          'assets/images/logo_agrocom.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'AGROCOM',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      'Tumbuh Bersama, Hasil Nyata',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.95),
                        shadows: const [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Welcome Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Selamat Datang',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AgriColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Masuk untuk melanjutkan kebun cabai',
                            style: TextStyle(
                              fontSize: 13,
                              color: AgriColors.textMuted,
                            ),
                          ),

                          if (_errorMessage != null) ...[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AgriColors.dangerLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: AgriColors.danger, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(fontSize: 12, color: AgriColors.danger, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 20),

                          // Username Input
                          TextField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              labelText: 'Username',
                              hintText: 'Contoh: andi',
                              prefixIcon: const Icon(Icons.person_outline, color: AgriColors.primary),
                              filled: true,
                              fillColor: AgriColors.bg,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: AgriColors.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: AgriColors.border),
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Password Input
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline, color: AgriColors.primary),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: AgriColors.textMuted,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              filled: true,
                              fillColor: AgriColors.bg,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: AgriColors.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: AgriColors.border),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AgriColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 3,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                    )
                                  : const Text(
                                      'Masuk',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          Center(
                            child: TextButton(
                              onPressed: () {},
                              child: const Text(
                                'Lupa password?',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AgriColors.textMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),

          // 4. Server Settings Button di Pojok Kanan Atas (Tepat di bawah Status Bar)
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.90),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.settings_outlined, color: AgriColors.primary),
                    onPressed: _showServerSettings,
                    tooltip: 'Atur Alamat Server',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
