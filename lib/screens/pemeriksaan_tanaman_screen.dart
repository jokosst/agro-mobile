import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/theme.dart';
import '../services/api_service.dart';

class PemeriksaanTanamanScreen extends StatefulWidget {
  const PemeriksaanTanamanScreen({super.key});

  @override
  State<PemeriksaanTanamanScreen> createState() => _PemeriksaanTanamanScreenState();
}

class _PemeriksaanTanamanScreenState extends State<PemeriksaanTanamanScreen> {
  String _selectedDaun = 'Normal';
  String _selectedBatang = 'Normal';
  String _selectedBunga = 'Normal';
  String _selectedBuah = 'Normal';

  final List<String> _optionsDaun = ['Normal', 'Layu', 'Menguning', 'Bercak', 'Rusak'];
  final List<String> _optionsBatang = ['Normal', 'Patah', 'Luka', 'Terganggu'];
  final List<String> _optionsBunga = ['Normal', 'Rontok', 'Terganggu'];
  final List<String> _optionsBuah = ['Normal', 'Rusak', 'Busuk', 'Hama'];

  final List<File> _photos = [];
  final _catatanController = TextEditingController();
  bool _isSaving = false;

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (picked != null) {
      setState(() {
        _photos.add(File(picked.path));
      });
    }
  }

  Future<void> _savePemeriksaan() async {
    setState(() => _isSaving = true);

    final res = await ApiService().submitPemeriksaan(
      kondisiDaun: _selectedDaun,
      kondisiBatang: _selectedBatang,
      kondisiBunga: _selectedBunga,
      kondisiBuah: _selectedBuah,
      photo: _photos.isNotEmpty ? _photos.first : null,
      catatan: _catatanController.text.trim(),
    );

    setState(() => _isSaving = false);

    if (!mounted) return;

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pemeriksaan tanaman berhasil disimpan ke Google Drive.')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Gagal menyimpan pemeriksaan.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Cek Kondisi Tanaman'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category: Daun
            _buildCategorySection(
              title: 'Daun',
              icon: Icons.eco,
              options: _optionsDaun,
              selected: _selectedDaun,
              onSelected: (val) => setState(() => _selectedDaun = val),
            ),

            const SizedBox(height: 18),

            // Category: Batang
            _buildCategorySection(
              title: 'Batang',
              icon: Icons.park_outlined,
              options: _optionsBatang,
              selected: _selectedBatang,
              onSelected: (val) => setState(() => _selectedBatang = val),
            ),

            const SizedBox(height: 18),

            // Category: Bunga
            _buildCategorySection(
              title: 'Bunga',
              icon: Icons.local_florist_outlined,
              options: _optionsBunga,
              selected: _selectedBunga,
              onSelected: (val) => setState(() => _selectedBunga = val),
            ),

            const SizedBox(height: 18),

            // Category: Buah
            _buildCategorySection(
              title: 'Buah',
              icon: Icons.grass,
              options: _optionsBuah,
              selected: _selectedBuah,
              onSelected: (val) => setState(() => _selectedBuah = val),
            ),

            const SizedBox(height: 24),

            // Foto Dokumentasi Sesuai Storyboard Screen 5
            const Text(
              'Foto Dokumentasi',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AgriColors.textDark),
            ),
            const SizedBox(height: 10),

            SizedBox(
              height: 80,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ..._photos.map(
                    (file) => Container(
                      width: 80,
                      height: 80,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AgriColors.border),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(file, fit: BoxFit.cover),
                      ),
                    ),
                  ),

                  // Add Photo Button
                  GestureDetector(
                    onTap: _takePhoto,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AgriColors.bg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AgriColors.border, style: BorderStyle.solid),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_outlined, color: AgriColors.primary, size: 28),
                          SizedBox(height: 4),
                          Text('Foto', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AgriColors.primary)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Catatan
            TextField(
              controller: _catatanController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Catatan Tambahan',
                hintText: 'Tuliskan observasi kondisi tanaman...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),

            const SizedBox(height: 28),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _savePemeriksaan,
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text('Simpan Pemeriksaan'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection({
    required String title,
    required IconData icon,
    required List<String> options,
    required String selected,
    required ValueChanged<String> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AgriColors.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AgriColors.textDark),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((opt) {
            final isSelected = selected == opt;
            return ChoiceChip(
              label: Text(opt),
              selected: isSelected,
              onSelected: (_) => onSelected(opt),
              selectedColor: opt == 'Normal' ? AgriColors.primary : AgriColors.danger,
              backgroundColor: AgriColors.bg,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AgriColors.textDark,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: isSelected ? Colors.transparent : AgriColors.border,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
