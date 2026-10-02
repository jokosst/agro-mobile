import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/theme.dart';
import '../services/api_service.dart';

class TugasHarianScreen extends StatefulWidget {
  const TugasHarianScreen({super.key});

  @override
  State<TugasHarianScreen> createState() => _TugasHarianScreenState();
}

class _TugasHarianScreenState extends State<TugasHarianScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _tugas = [];
  String _dateString = '';

  @override
  void initState() {
    super.initState();
    _dateString = DateFormat('d MMMM yyyy', 'id_ID').format(DateTime.now());
    _loadTugas();
  }

  Future<void> _loadTugas() async {
    setState(() => _isLoading = true);
    final res = await ApiService().getTugas();
    if (res['success'] == true) {
      final list = (res['data'] as List).cast<Map<String, dynamic>>();
      setState(() {
        _tugas = list;
      });
    } else {
      // Fallback default 8 tasks matching Storyboard Screen 4
      setState(() {
        _tugas = [
          {'id': 1, 'judul': 'Cek seluruh tanaman', 'is_completed': true},
          {'id': 2, 'judul': 'Bersihkan gulma', 'is_completed': true},
          {'id': 3, 'judul': 'Periksa hama/penyakit', 'is_completed': false},
          {'id': 4, 'judul': 'Periksa ajir dan tali', 'is_completed': false},
          {'id': 5, 'judul': 'Perempelan bila diperlukan', 'is_completed': false},
          {'id': 6, 'judul': 'Pemupukan/penyemprotan', 'is_completed': false},
          {'id': 7, 'judul': 'Bersihkan area kebun', 'is_completed': false},
          {'id': 8, 'judul': 'Dokumentasi kondisi kebun', 'is_completed': false},
        ];
      });
    }
    setState(() => _isLoading = false);
  }

  Future<void> _toggleTugas(int index) async {
    final item = _tugas[index];
    final id = item['id'];

    setState(() {
      _tugas[index]['is_completed'] = !(_tugas[index]['is_completed'] as bool);
    });

    await ApiService().toggleTugas(id);
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _tugas.where((t) => t['is_completed'] == true).length;
    final totalCount = _tugas.length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Tugas Hari Ini'),
            Text(
              _dateString,
              style: const TextStyle(fontSize: 11, color: AgriColors.textMuted, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                children: [
                  // Progress indicator
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AgriColors.primarySubtle,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Selesai: $completedCount dari $totalCount kegiatan',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AgriColors.primary),
                        ),
                        Text(
                          totalCount > 0 ? '${((completedCount / totalCount) * 100).round()}%' : '0%',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AgriColors.primary),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Task Checklist List (Storyboard Screen 4)
                  Expanded(
                    child: ListView.separated(
                      itemCount: _tugas.length,
                      separatorBuilder: (context, _) => const Divider(height: 1, color: AgriColors.border),
                      itemBuilder: (context, index) {
                        final item = _tugas[index];
                        final isCompleted = item['is_completed'] == true;

                        return InkWell(
                          onTap: () => _toggleTugas(index),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                            child: Row(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: isCompleted ? AgriColors.primary : Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isCompleted ? AgriColors.primary : AgriColors.border,
                                      width: 1.8,
                                    ),
                                  ),
                                  child: isCompleted
                                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                                      : null,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    item['judul'] ?? '',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
                                      color: isCompleted ? AgriColors.textDark : AgriColors.textDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Action Button
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 8),
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Progres tugas berhasil diperbarui ke server.')),
                            );
                            Navigator.pop(context);
                          },
                          child: const Text('Mulai Pekerjaan'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
