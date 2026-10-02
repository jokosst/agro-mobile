import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/theme.dart';
import '../services/api_service.dart';

class RekapLaporanScreen extends StatefulWidget {
  const RekapLaporanScreen({super.key});

  @override
  State<RekapLaporanScreen> createState() => _RekapLaporanScreenState();
}

class _RekapLaporanScreenState extends State<RekapLaporanScreen> {
  String _selectedFilter = 'Harian';
  bool _isLoading = true;
  Map<String, dynamic> _summary = {
    'total_kehadiran': '1/1',
    'laporan_masuk': 1,
    'masalah_tanaman': 7,
    'hasil_panen_kg': 0,
    'kehadiran_persen': 100,
  };

  @override
  void initState() {
    super.initState();
    _loadRekap();
  }

  Future<void> _loadRekap() async {
    setState(() => _isLoading = true);
    final res = await ApiService().getRekapLaporan();
    if (res['success'] == true && res['summary'] != null) {
      setState(() {
        _summary = res['summary'];
      });
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = '${DateFormat('d MMM yyyy').format(now)} - ${DateFormat('d MMM yyyy').format(now)}';

    return Scaffold(
      backgroundColor: AgriColors.bg,
      appBar: AppBar(
        title: const Text('Rekap Laporan'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadRekap,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              // Date Range Indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AgriColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dateStr,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AgriColors.textDark),
                    ),
                    const Icon(Icons.calendar_month_outlined, size: 18, color: AgriColors.primary),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Filter Chips: Harian, Mingguan, Bulanan Sesuai Mockup 11
              Row(
                children: ['Harian', 'Mingguan', 'Bulanan'].map((f) {
                  final isSelected = _selectedFilter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f),
                      selected: isSelected,
                      selectedColor: AgriColors.primary,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AgriColors.textDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      onSelected: (_) => setState(() => _selectedFilter = f),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 18),

              // 4 Stat Cards Sesuai Storyboard Screen 11
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      label: 'Total Kehadiran',
                      value: _summary['total_kehadiran']?.toString() ?? '1/1',
                      icon: Icons.people_outline,
                      color: AgriColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      label: 'Laporan Masuk',
                      value: _summary['laporan_masuk']?.toString() ?? '1',
                      icon: Icons.assignment_turned_in_outlined,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      label: 'Masalah Tanaman',
                      value: _summary['masalah_tanaman']?.toString() ?? '7',
                      icon: Icons.warning_amber_rounded,
                      color: AgriColors.danger,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      label: 'Hasil Panen',
                      value: '${_summary['hasil_panen_kg'] ?? 0} kg',
                      icon: Icons.eco_outlined,
                      color: AgriColors.success,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Grafik Kehadiran Card Sesuai Storyboard Screen 11
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AgriColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Grafik Kehadiran',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AgriColors.textDark),
                        ),
                        Text(
                          '${_summary['kehadiran_persen'] ?? 100}%',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AgriColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: const LinearProgressIndicator(
                        value: 1.0,
                        minHeight: 12,
                        backgroundColor: AgriColors.bg,
                        valueColor: AlwaysStoppedAnimation<Color>(AgriColors.primary),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1 dari 1 pekerja telah hadir & absen masuk',
                      style: TextStyle(fontSize: 12, color: AgriColors.textMuted),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Laporan Pekerja Hari Ini Card Sesuai Mockup 9
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AgriColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Laporan Pekerja Aktif',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AgriColors.textDark),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: AgriColors.primary,
                          child: const Text('A', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Andi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text('Hadir: 07:02 - 16:31 WIB', style: TextStyle(fontSize: 12, color: AgriColors.textMuted)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AgriColors.successLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Selesai',
                            style: TextStyle(color: AgriColors.success, fontWeight: FontWeight.bold, fontSize: 11),
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
      ),
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AgriColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AgriColors.textMuted)),
              Icon(icon, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color),
          ),
        ],
      ),
    );
  }
}
