import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../constants/theme.dart';
import '../services/api_service.dart';

class LaporanHarianScreen extends StatefulWidget {
  const LaporanHarianScreen({super.key});

  @override
  State<LaporanHarianScreen> createState() => _LaporanHarianScreenState();
}

class _LaporanHarianScreenState extends State<LaporanHarianScreen> {
  String _dateString = '';
  String _kondisiTanaman = 'Baik';
  String _gulma = 'Sedang';
  String _hama = 'Ada';
  String _penyakit = 'Tidak ada';
  String _ajir = 'Baik';
  String _perempelan = 'Sudah';
  String _pemupukan = 'Dilakukan';
  String _penyemprotan = 'Tidak';
  String _kendala = 'Tidak ada';

  File? _fotoSebelum;
  File? _fotoSesudah;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _dateString = DateFormat('d MMMM yyyy', 'id_ID').format(DateTime.now());
  }

  Future<void> _pickPhoto(bool isSebelum) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (picked != null) {
      setState(() {
        if (isSebelum) {
          _fotoSebelum = File(picked.path);
        } else {
          _fotoSesudah = File(picked.path);
        }
      });
    }
  }

  Future<void> _submitLaporan() async {
    setState(() => _isSubmitting = true);

    final res = await ApiService().submitLaporanHarian(
      kondisiTanaman: _kondisiTanaman,
      gulma: _gulma,
      hama: _hama,
      penyakit: _penyakit,
      ajir: _ajir,
      perempelan: _perempelan,
      pemupukan: _pemupukan,
      penyemprotan: _penyemprotan,
      kendala: _kendala,
      fotoSebelum: _fotoSebelum,
      fotoSesudah: _fotoSesudah,
    );

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Laporan harian berhasil dikirim ke Google Drive dan server.')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Gagal mengirim laporan harian.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Laporan Harian'),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // Status Items List Sesuai Storyboard Screen 7
            _buildSelectorRow(
              title: '🌱 Kondisi tanaman',
              value: _kondisiTanaman,
              options: ['Baik', 'Cukup', 'Buruk'],
              onChanged: (val) => setState(() => _kondisiTanaman = val),
            ),
            _buildSelectorRow(
              title: '🌿 Gulma',
              value: _gulma,
              options: ['Bersih', 'Sedang', 'Banyak'],
              onChanged: (val) => setState(() => _gulma = val),
            ),
            _buildSelectorRow(
              title: '🐛 Hama',
              value: _hama,
              options: ['Ada', 'Tidak ada'],
              onChanged: (val) => setState(() => _hama = val),
            ),
            _buildSelectorRow(
              title: '🦠 Penyakit',
              value: _penyakit,
              options: ['Ada', 'Tidak ada'],
              onChanged: (val) => setState(() => _penyakit = val),
            ),
            _buildSelectorRow(
              title: '🪢 Ajir',
              value: _ajir,
              options: ['Baik', 'Perlu perbaikan'],
              onChanged: (val) => setState(() => _ajir = val),
            ),
            _buildSelectorRow(
              title: '✂️ Perempelan',
              value: _perempelan,
              options: ['Sudah', 'Belum'],
              onChanged: (val) => setState(() => _perempelan = val),
            ),
            _buildSelectorRow(
              title: '🧪 Pemupukan',
              value: _pemupukan,
              options: ['Dilakukan', 'Tidak'],
              onChanged: (val) => setState(() => _pemupukan = val),
            ),
            _buildSelectorRow(
              title: '💨 Penyemprotan',
              value: _penyemprotan,
              options: ['Dilakukan', 'Tidak'],
              onChanged: (val) => setState(() => _penyemprotan = val),
            ),
            _buildSelectorRow(
              title: '📝 Kendala',
              value: _kendala,
              options: ['Tidak ada', 'Ada kendala'],
              onChanged: (val) => setState(() => _kendala = val),
            ),

            const SizedBox(height: 20),

            // Foto Sebelum & Sesudah Sesuai Storyboard Screen 7
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        'Sebelum',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AgriColors.textDark),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _pickPhoto(true),
                        child: Container(
                          height: 110,
                          decoration: BoxDecoration(
                            color: AgriColors.bg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AgriColors.border),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: _fotoSebelum != null
                                ? Image.file(_fotoSebelum!, fit: BoxFit.cover, width: double.infinity)
                                : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.camera_alt_outlined, color: AgriColors.primary, size: 28),
                                      SizedBox(height: 4),
                                      Text('Foto Sebelum', style: TextStyle(fontSize: 11, color: AgriColors.textMuted)),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        'Sesudah',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AgriColors.textDark),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _pickPhoto(false),
                        child: Container(
                          height: 110,
                          decoration: BoxDecoration(
                            color: AgriColors.bg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AgriColors.border),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: _fotoSesudah != null
                                ? Image.file(_fotoSesudah!, fit: BoxFit.cover, width: double.infinity)
                                : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.camera_alt_outlined, color: AgriColors.primary, size: 28),
                                      SizedBox(height: 4),
                                      Text('Foto Sesudah', style: TextStyle(fontSize: 11, color: AgriColors.textMuted)),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitLaporan,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text('Kirim Laporan'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectorRow({
    required String title,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AgriColors.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AgriColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AgriColors.textDark),
          ),
          DropdownButton<String>(
            value: value,
            underline: const SizedBox(),
            style: const TextStyle(color: AgriColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
            items: options.map((opt) {
              return DropdownMenuItem(value: opt, child: Text(opt));
            }).toList(),
            onChanged: (val) {
              if (val != null) onChanged(val);
            },
          ),
        ],
      ),
    );
  }
}
