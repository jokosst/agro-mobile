import 'package:flutter/material.dart';
import '../constants/theme.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'rekap_laporan_screen.dart';

class MenuAdminScreen extends StatefulWidget {
  const MenuAdminScreen({super.key});

  @override
  State<MenuAdminScreen> createState() => _MenuAdminScreenState();
}

class _MenuAdminScreenState extends State<MenuAdminScreen> {
  bool _isLoading = true;
  String _name = 'Pengguna';
  String _username = 'user';
  String _email = 'user@agrocom.id';
  String _role = 'pekerja';
  String _phone = '-';
  String _kebunName = 'Kebun Cabai Agrocom';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    final res = await ApiService().getMe();
    if (res['success'] == true && mounted) {
      final user = res['user'] ?? {};
      final kebun = res['kebun'] ?? {};
      setState(() {
        _name = user['name'] ?? 'Pengguna';
        _username = user['username'] ?? 'user';
        _email = user['email'] ?? 'user@agrocom.id';
        _role = user['role'] ?? 'pekerja';
        _phone = user['phone'] ?? '-';
        if (kebun['nama'] != null) {
          _kebunName = kebun['nama'];
        }
      });
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AgriColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ApiService().clearAuth();
      if (!context.mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  // --- MODAL EDIT PROFIL ---
  void _showEditProfileModal(BuildContext context) {
    final nameCtrl = TextEditingController(text: _name);
    final emailCtrl = TextEditingController(text: _email);
    final phoneCtrl = TextEditingController(text: _phone == '-' ? '' : _phone);
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: const [
                        Icon(Icons.person_outline, color: AgriColors.primary, size: 24),
                        SizedBox(width: 10),
                        Text(
                          'Update Data Profil',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AgriColors.textDark),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Perbarui identitas akun dan nomor kontak Anda.',
                      style: TextStyle(fontSize: 12, color: AgriColors.textMuted),
                    ),
                    const SizedBox(height: 20),

                    // Field Nama
                    const Text('Nama Lengkap', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AgriColors.textDark)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        hintText: 'Masukkan nama lengkap',
                        prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty) ? 'Nama lengkap wajib diisi' : null,
                    ),
                    const SizedBox(height: 14),

                    // Field Email
                    const Text('Alamat Email', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AgriColors.textDark)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'nama@domain.com',
                        prefixIcon: const Icon(Icons.email_outlined, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Email wajib diisi';
                        if (!val.contains('@') || !val.contains('.')) return 'Format email tidak valid';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Field Telepon / WA
                    const Text('Nomor Telepon / WhatsApp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AgriColors.textDark)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: 'Contoh: 081234567890',
                        prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Tombol Simpan
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AgriColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: isSaving
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                setModalState(() => isSaving = true);

                                final res = await ApiService().updateProfile(
                                  name: nameCtrl.text.trim(),
                                  email: emailCtrl.text.trim(),
                                  phone: phoneCtrl.text.trim(),
                                );

                                setModalState(() => isSaving = false);

                                if (res['success'] == true) {
                                  if (!context.mounted) return;
                                  Navigator.pop(ctx);
                                  setState(() {
                                    _name = nameCtrl.text.trim();
                                    _email = emailCtrl.text.trim();
                                    _phone = phoneCtrl.text.trim().isEmpty ? '-' : phoneCtrl.text.trim();
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(res['message'] ?? 'Profil berhasil diperbarui!')),
                                  );
                                } else {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: AgriColors.danger,
                                      content: Text(res['message'] ?? 'Gagal memperbarui profil'),
                                    ),
                                  );
                                }
                              },
                        child: isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Simpan Perubahan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- MODAL UBAH PASSWORD ---
  void _showChangePasswordModal(BuildContext context) {
    final currentPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: const [
                        Icon(Icons.lock_outline, color: AgriColors.primary, size: 24),
                        SizedBox(width: 10),
                        Text(
                          'Ubah Kata Sandi',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AgriColors.textDark),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Masukkan password saat ini dan buat password baru minimal 6 karakter.',
                      style: TextStyle(fontSize: 12, color: AgriColors.textMuted),
                    ),
                    const SizedBox(height: 20),

                    // Password Lama
                    const Text('Password Saat Ini', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AgriColors.textDark)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: currentPassCtrl,
                      obscureText: obscureCurrent,
                      decoration: InputDecoration(
                        hintText: 'Password saat ini',
                        prefixIcon: const Icon(Icons.key_outlined, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(obscureCurrent ? Icons.visibility_off : Icons.visibility, size: 20),
                          onPressed: () => setModalState(() => obscureCurrent = !obscureCurrent),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      validator: (val) => (val == null || val.isEmpty) ? 'Password saat ini wajib diisi' : null,
                    ),
                    const SizedBox(height: 14),

                    // Password Baru
                    const Text('Password Baru', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AgriColors.textDark)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: newPassCtrl,
                      obscureText: obscureNew,
                      decoration: InputDecoration(
                        hintText: 'Minimal 6 karakter',
                        prefixIcon: const Icon(Icons.lock_reset, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility, size: 20),
                          onPressed: () => setModalState(() => obscureNew = !obscureNew),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Password baru wajib diisi';
                        if (val.length < 6) return 'Password minimal 6 karakter';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Konfirmasi Password Baru
                    const Text('Konfirmasi Password Baru', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AgriColors.textDark)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: confirmPassCtrl,
                      obscureText: obscureConfirm,
                      decoration: InputDecoration(
                        hintText: 'Ulangi password baru',
                        prefixIcon: const Icon(Icons.check_circle_outline, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility, size: 20),
                          onPressed: () => setModalState(() => obscureConfirm = !obscureConfirm),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Konfirmasi password wajib diisi';
                        if (val != newPassCtrl.text) return 'Konfirmasi password tidak cocok';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Tombol Submit
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AgriColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: isSaving
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                setModalState(() => isSaving = true);

                                final res = await ApiService().updatePassword(
                                  currentPassword: currentPassCtrl.text,
                                  newPassword: newPassCtrl.text,
                                  confirmPassword: confirmPassCtrl.text,
                                );

                                setModalState(() => isSaving = false);

                                if (res['success'] == true) {
                                  if (!context.mounted) return;
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(res['message'] ?? 'Password berhasil diperbarui!')),
                                  );
                                } else {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: AgriColors.danger,
                                      content: Text(res['message'] ?? 'Gagal memperbarui password'),
                                    ),
                                  );
                                }
                              },
                        child: isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Simpan Password Baru', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- MODAL EXPORT DATA ---
  void _showExportDataModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.file_download_outlined, color: AgriColors.primary, size: 24),
                  SizedBox(width: 10),
                  Text(
                    'Export & Unduh Laporan',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AgriColors.textDark),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Pilih format laporan yang ingin diunduh:',
                style: TextStyle(fontSize: 12, color: AgriColors.textMuted),
              ),
              const SizedBox(height: 16),
              _buildExportOption(
                title: 'Laporan Harian Pekerja (PDF)',
                subtitle: 'Ringkasan kegiatan, checklist 8 tugas & foto lapangan',
                icon: Icons.picture_as_pdf,
                color: Colors.red.shade700,
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Laporan PDF disiapkan dari Web Admin.')),
                  );
                },
              ),
              _buildExportOption(
                title: 'Data Presensi & GPS (Excel / CSV)',
                subtitle: 'Log jam masuk, pulang, dan validasi radius kebun',
                icon: Icons.table_chart_outlined,
                color: Colors.green.shade700,
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ekspor presensi siap diunduh di Web Admin.')),
                  );
                },
              ),
              _buildExportOption(
                title: 'Rekap Hama & Masalah Blok (PDF)',
                subtitle: 'Daftar tanaman bergejala, foto, dan status penanganan',
                icon: Icons.bug_report_outlined,
                color: AgriColors.warning,
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Data rekap hama disiapkan.')),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildExportOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AgriColors.border),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AgriColors.textDark)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 10, color: AgriColors.textMuted)),
        trailing: const Icon(Icons.download, size: 18, color: AgriColors.primary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AgriColors.bg,
      appBar: AppBar(
        title: const Text('Profil Pengguna'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserProfile,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Header Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AgriColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: AgriColors.primary,
                            child: Text(
                              _name.isNotEmpty ? _name[0].toUpperCase() : 'U',
                              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _name,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AgriColors.textDark),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '@$_username • $_email',
                            style: const TextStyle(fontSize: 13, color: AgriColors.textMuted),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _role == 'admin' ? Colors.blue.shade50 : AgriColors.primarySubtle,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _role == 'admin' ? 'ADMINISTRATOR' : 'PEKERJA KEBUN',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _role == 'admin' ? Colors.blue.shade700 : AgriColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.phone_outlined, size: 12, color: AgriColors.textMuted),
                                    const SizedBox(width: 4),
                                    Text(
                                      _phone,
                                      style: const TextStyle(fontSize: 11, color: AgriColors.textMuted, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.eco_outlined, size: 14, color: AgriColors.primary),
                              const SizedBox(width: 6),
                              Text(
                                _kebunName,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AgriColors.primary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Section: Pengaturan Akun & Profil
                    const Text(
                      'Pengaturan Akun & Profil',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AgriColors.textMuted),
                    ),
                    const SizedBox(height: 8),
                    _buildMenuCard([
                      _buildMenuItem(
                        title: 'Update Data Profil',
                        subtitle: 'Ubah nama lengkap, email, dan nomor WhatsApp',
                        icon: Icons.person_outline,
                        onTap: () => _showEditProfileModal(context),
                      ),
                      _buildMenuItem(
                        title: 'Ubah Kata Sandi (Password)',
                        subtitle: 'Ganti password akun untuk keamanan login',
                        icon: Icons.lock_outline,
                        isLast: true,
                        onTap: () => _showChangePasswordModal(context),
                      ),
                    ]),

                    const SizedBox(height: 20),

                    // Section: Laporan & Arsip (Biarkan Ada)
                    const Text(
                      'Laporan & Arsip',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AgriColors.textMuted),
                    ),
                    const SizedBox(height: 8),
                    _buildMenuCard([
                      _buildMenuItem(
                        title: 'Rekap Laporan Harian',
                        subtitle: 'Analisis rekap checklist & kegiatan lapangan',
                        icon: Icons.analytics_outlined,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RekapLaporanScreen()),
                        ),
                      ),
                      _buildMenuItem(
                        title: 'Export & Unduh Data',
                        subtitle: 'Ekspor laporan format PDF dan Excel',
                        icon: Icons.file_download_outlined,
                        isLast: true,
                        onTap: () => _showExportDataModal(context),
                      ),
                    ]),

                    const SizedBox(height: 32),

                    // Logout Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () => _handleLogout(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AgriColors.danger),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text(
                          'Logout',
                          style: TextStyle(color: AgriColors.danger, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Center(
                      child: Text(
                        'AGROCOM Mobile v1.0.0 • Google Drive Storage',
                        style: TextStyle(fontSize: 11, color: AgriColors.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMenuCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AgriColors.border),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuItem({
    required String title,
    String? subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AgriColors.primarySubtle,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AgriColors.primary, size: 20),
          ),
          title: Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AgriColors.textDark),
          ),
          subtitle: subtitle != null
              ? Text(subtitle, style: const TextStyle(fontSize: 11, color: AgriColors.textMuted))
              : null,
          trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AgriColors.textMuted),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        ),
        if (!isLast) const Divider(height: 1, color: AgriColors.border),
      ],
    );
  }
}
