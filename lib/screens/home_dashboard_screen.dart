import 'package:flutter/material.dart';
import '../constants/theme.dart';
import '../services/api_service.dart';
import 'absen_pagi_screen.dart';
import 'tugas_harian_screen.dart';
import 'pemeriksaan_tanaman_screen.dart';
import 'laporan_masalah_screen.dart';
import 'laporan_harian_screen.dart';
import 'absen_pulang_screen.dart';
import 'monitoring_kebun_screen.dart';
import 'rekap_laporan_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  bool _isLoading = true;
  String _userName = 'Andi';
  String _jamMasuk = '07:02';
  bool _isHadir = true;
  int _tanamanBermasalah = 2;
  int _laporanHama = 5;
  int _areaPerluDibersihkan = 3;
  int _laporanMasuk = 1;
  String _kondisiKebun = 'Baik';

  String _kebunName = 'Kebun Cabai Agrocom';
  String _kebunLokasi = 'Sambas, Kalimantan Barat';
  int _unreadNotifikasi = 0;
  List<dynamic> _notifikasiList = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    final res = await ApiService().getNotifikasi();
    if (res['success'] == true && mounted) {
      setState(() {
        _notifikasiList = res['data'] ?? [];
        _unreadNotifikasi = res['unread_count'] ?? 0;
      });
    }
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    final res = await ApiService().getMe();
    if (res['success'] == true) {
      final user = res['user'] ?? {};
      final absensi = res['absensi_hari_ini'];
      final stats = res['stats'] ?? {};
      final kebun = res['kebun'] ?? {};

      setState(() {
        _userName = user['name'] ?? 'Andi';
        if (kebun['nama'] != null) _kebunName = kebun['nama'];
        if (kebun['lokasi_text'] != null) _kebunLokasi = kebun['lokasi_text'];

        if (absensi != null && absensi['jam_masuk'] != null) {
          _isHadir = true;
          _jamMasuk = absensi['jam_masuk'].toString().substring(0, 5);
        } else {
          _isHadir = false;
        }
        _tanamanBermasalah = stats['tanaman_bermasalah'] ?? 2;
        _laporanHama = stats['laporan_hama'] ?? 5;
        _areaPerluDibersihkan = stats['area_perlu_dibersihkan'] ?? 3;
        _laporanMasuk = stats['laporan_masuk'] ?? 1;
        _kondisiKebun = stats['kondisi_kebun'] ?? 'Baik';
      });
    }
    setState(() => _isLoading = false);
  }

  void _showNotifikasiBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active, color: AgriColors.primary, size: 24),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Pusat Notifikasi',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AgriColors.textDark),
                      ),
                    ),
                    if (_unreadNotifikasi > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AgriColors.chiliRed.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$_unreadNotifikasi Baru',
                          style: const TextStyle(color: AgriColors.chiliRed, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _notifikasiList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline, size: 64, color: AgriColors.primary.withValues(alpha: 0.5)),
                            const SizedBox(height: 12),
                            const Text(
                              'Tidak Ada Notifikasi Tertunda',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AgriColors.textDark),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Semua tugas dan absensi Anda berjalan lancar!',
                              style: TextStyle(fontSize: 13, color: AgriColors.textMuted),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _notifikasiList.length,
                        separatorBuilder: (ctx, index) => const SizedBox(height: 10),
                        itemBuilder: (ctx, index) {
                          final item = _notifikasiList[index];
                          final type = item['type'] ?? 'info';
                          Color iconColor;
                          Color bgColor;
                          IconData iconData;

                          switch (type) {
                            case 'hama':
                              iconColor = AgriColors.chiliRed;
                              bgColor = AgriColors.dangerLight;
                              iconData = Icons.pest_control_outlined;
                              break;
                            case 'tugas':
                              iconColor = AgriColors.warning;
                              bgColor = AgriColors.warningLight;
                              iconData = Icons.checklist_outlined;
                              break;
                            case 'absen':
                              iconColor = AgriColors.primary;
                              bgColor = AgriColors.primarySubtle;
                              iconData = Icons.access_time_outlined;
                              break;
                            default:
                              iconColor = AgriColors.primary;
                              bgColor = AgriColors.primarySubtle;
                              iconData = Icons.notifications_none;
                          }

                          return InkWell(
                            onTap: () {
                              Navigator.pop(ctx);
                              if (type == 'hama') {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const MonitoringKebunScreen()));
                              } else if (type == 'tugas') {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const TugasHarianScreen()));
                              } else if (type == 'absen') {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const AbsenPagiScreen()));
                              }
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AgriColors.border),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: bgColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(iconData, color: iconColor, size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item['title'] ?? 'Pemberitahuan',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: AgriColors.textDark,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              item['time'] ?? 'Hari ini',
                                              style: const TextStyle(fontSize: 11, color: AgriColors.textMuted),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item['message'] ?? '',
                                          style: const TextStyle(fontSize: 12, color: AgriColors.textMuted),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Text(
                                              type == 'hama'
                                                  ? 'Buka Peta Blok →'
                                                  : type == 'tugas'
                                                      ? 'Buka Daftar Tugas →'
                                                      : 'Buka Form Absen →',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: iconColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AgriColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 20,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AgriColors.primary,
              child: const Text('A', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, $_userName',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AgriColors.textDark),
                ),
                const Text(
                  'Semangat hari ini!',
                  style: TextStyle(fontSize: 12, color: AgriColors.textMuted),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none, color: AgriColors.textDark),
                tooltip: 'Pusat Notifikasi',
                onPressed: () => _showNotifikasiBottomSheet(context),
              ),
              if (_unreadNotifikasi > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AgriColors.chiliRed,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$_unreadNotifikasi',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await Future.wait([
                  _fetchDashboardData(),
                  _fetchNotifications(),
                ]);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              // Kebun Header Card (Clickable to Map Screen)
              InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MonitoringKebunScreen()),
                ),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AgriColors.primary, AgriColors.primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AgriColors.primary.withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.white, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _kebunName,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.eco, color: Colors.white, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  _kondisiKebun,
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 24, top: 2),
                        child: Text(
                          _kebunLokasi,
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Status Hari Ini
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AgriColors.successLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _isHadir ? 'Hadir' : 'Belum Hadir',
                                    style: const TextStyle(color: AgriColors.success, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _isHadir ? 'Masuk $_jamMasuk WIB' : 'Belum Absen Masuk',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AgriColors.textDark),
                                ),
                              ],
                            ),
                            const Row(
                              children: [
                                Text(
                                  'Peta Lahan',
                                  style: TextStyle(fontSize: 11, color: AgriColors.primary, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward_ios, color: AgriColors.primary, size: 12),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 4 Stat Cards Sesuai Storyboard Screen 2 (Clickable to respective screens)
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.45,
                children: [
                  _buildStatCard(
                    count: _tanamanBermasalah.toString(),
                    label: 'Tanaman bermasalah',
                    color: AgriColors.danger,
                    bgColor: AgriColors.dangerLight,
                    icon: Icons.warning_amber_rounded,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MonitoringKebunScreen()),
                    ),
                  ),
                  _buildStatCard(
                    count: _laporanHama.toString(),
                    label: 'Laporan hama',
                    color: AgriColors.warning,
                    bgColor: AgriColors.warningLight,
                    icon: Icons.bug_report_outlined,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LaporanMasalahScreen()),
                    ),
                  ),
                  _buildStatCard(
                    count: _areaPerluDibersihkan.toString(),
                    label: 'Area perlu dibersihkan',
                    color: AgriColors.warning,
                    bgColor: AgriColors.warningLight,
                    icon: Icons.cleaning_services_outlined,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TugasHarianScreen()),
                    ),
                  ),
                  _buildStatCard(
                    count: _laporanMasuk.toString(),
                    label: 'Laporan masuk',
                    color: AgriColors.primary,
                    bgColor: AgriColors.primarySubtle,
                    icon: Icons.assignment_outlined,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RekapLaporanScreen()),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Quick Actions Menu (Alur Kerja Eksekusi Lapangan)
              const Text(
                'Alur Kerja Petani Hari Ini',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AgriColors.textDark,
                ),
              ),

              const SizedBox(height: 12),

              _buildActionTile(
                step: '1',
                title: 'Absen Pagi (Masuk)',
                subtitle: 'Kamera selfie + Validasi GPS kebun (<= 50m)',
                icon: Icons.camera_front_outlined,
                color: AgriColors.primary,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AbsenPagiScreen()),
                ),
              ),

              _buildActionTile(
                step: '2',
                title: 'Tugas Hari Ini',
                subtitle: 'Checklist 8 kegiatan pemeliharaan kebun cabai',
                icon: Icons.checklist_outlined,
                color: Colors.blue.shade700,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TugasHarianScreen()),
                ),
              ),

              _buildActionTile(
                step: '3',
                title: 'Pemeriksaan Tanaman',
                subtitle: 'Cek kondisi daun, batang, bunga & buah + foto',
                icon: Icons.search_outlined,
                color: Colors.teal.shade700,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PemeriksaanTanamanScreen()),
                ),
              ),

              _buildActionTile(
                step: '4',
                title: 'Lapor Masalah & Hama',
                subtitle: 'Laporkan hama/penyakit per blok lahan cabai',
                icon: Icons.pest_control_outlined,
                color: AgriColors.chiliRed,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LaporanMasalahScreen()),
                ),
              ),

              _buildActionTile(
                step: '5',
                title: 'Laporan Harian (Rangkuman)',
                subtitle: 'Kondisi gulma, ajir, pemupukan + Foto Sebelum & Sesudah',
                icon: Icons.file_copy_outlined,
                color: Colors.indigo.shade700,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LaporanHarianScreen()),
                ),
              ),

              _buildActionTile(
                step: '6',
                title: 'Absen Pulang',
                subtitle: 'Selfie pulang + GPS + Status selesai/sebagian',
                icon: Icons.logout_outlined,
                color: Colors.deepPurple.shade700,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AbsenPulangScreen()),
                ),
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String count,
    required String label,
    required Color color,
    required Color bgColor,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AgriColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  count,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
              ],
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AgriColors.textDark,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required String step,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AgriColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AgriColors.textDark),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 11, color: AgriColors.textMuted),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AgriColors.textMuted),
      ),
    );
  }
}
