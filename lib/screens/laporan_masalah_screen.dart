import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/theme.dart';
import '../services/api_service.dart';

class LaporanMasalahScreen extends StatefulWidget {
  final int? initialBlokId;

  const LaporanMasalahScreen({super.key, this.initialBlokId});

  @override
  State<LaporanMasalahScreen> createState() => _LaporanMasalahScreenState();
}

class _LaporanMasalahScreenState extends State<LaporanMasalahScreen> {
  String _jenisMasalah = 'Hama';
  int? _selectedBlokId;
  String _selectedBlokKode = 'Blok A';
  final _barisController = TextEditingController(text: 'Baris 3');
  final _jumlahTanamanController = TextEditingController(text: '5');
  final _kondisiController = TextEditingController(text: 'Kutu Kebul (Bemisia tabaci)');
  final _catatanController = TextEditingController(text: 'Perlu penyemprotan insektisida');

  List<dynamic> _bloks = [];
  List<dynamic> _masterHama = [];
  Map<String, dynamic>? _selectedMasterItem;
  bool _isLoadingMaster = true;

  final List<File> _photos = [];
  bool _isSubmitting = false;

  final List<String> _jenisOptions = ['Hama', 'Penyakit', 'Gulma', 'Ajir Rusak', 'Lainnya'];

  @override
  void initState() {
    super.initState();
    _selectedBlokId = widget.initialBlokId;
    _fetchMasterData();
  }

  @override
  void dispose() {
    _barisController.dispose();
    _jumlahTanamanController.dispose();
    _kondisiController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  Future<void> _fetchMasterData() async {
    setState(() => _isLoadingMaster = true);

    final resLahan = await ApiService().getMasterLahan();
    final resDukung = await ApiService().getMasterDataDukung();

    if (mounted) {
      setState(() {
        if (resLahan['success'] == true && resLahan['data'] != null) {
          _bloks = resLahan['data']['bloks'] ?? [];
          if (_bloks.isNotEmpty) {
            if (_selectedBlokId == null) {
              _selectedBlokId = _bloks.first['id'];
              _selectedBlokKode = _bloks.first['kode_blok'] ?? 'Blok A';
            } else {
              final match = _bloks.firstWhere((b) => b['id'] == _selectedBlokId, orElse: () => _bloks.first);
              _selectedBlokKode = match['kode_blok'] ?? 'Blok A';
            }
          }
        }

        if (resDukung['success'] == true && resDukung['data'] != null) {
          _masterHama = resDukung['data'] as List;
          _filterMasterItem();
        }
        _isLoadingMaster = false;
      });
    }
  }

  void _filterMasterItem() {
    final matching = _masterHama.where((item) =>
        (item['kategori'] ?? '').toString().toLowerCase() == _jenisMasalah.toLowerCase()).toList();

    if (matching.isNotEmpty) {
      _selectedMasterItem = matching.first as Map<String, dynamic>;
      _kondisiController.text = _selectedMasterItem!['nama'] ?? '';
      _catatanController.text = _selectedMasterItem!['solusi_pengendalian'] ?? '';
    } else {
      _selectedMasterItem = null;
    }
  }

  Future<void> _addPhoto() async {
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

  Future<void> _submitMasalah() async {
    final barisText = _barisController.text.trim();
    final lokasi = '$_selectedBlokKode - $barisText';
    final jumlah = int.tryParse(_jumlahTanamanController.text.trim()) ?? 1;
    final kondisi = _kondisiController.text.trim();

    if (kondisi.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kondisi masalah tanaman wajib diisi.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final res = await ApiService().submitLaporanMasalah(
      jenisMasalah: _jenisMasalah,
      baris: lokasi,
      jumlahTanaman: jumlah,
      kondisi: kondisi,
      photos: _photos,
      catatan: _catatanController.text.trim(),
      blokId: _selectedBlokId,
    );

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Laporan masalah berhasil dikirim ke server & tersinkron ke Master Admin.')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Gagal menyimpan laporan masalah.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final matchingMaster = _masterHama.where((item) =>
        (item['kategori'] ?? '').toString().toLowerCase() == _jenisMasalah.toLowerCase()).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Laporkan Masalah Tanaman'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoadingMaster
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dropdown Blok Lahan (Dari Master Lahan)
                  const Text(
                    'Pilih Blok Lahan (Master Data)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AgriColors.textDark),
                  ),
                  const SizedBox(height: 6),
                  if (_bloks.isNotEmpty)
                    DropdownButtonFormField<int>(
                      initialValue: _selectedBlokId,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        prefixIcon: const Icon(Icons.grid_view_outlined, color: AgriColors.primary),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: _bloks.map((b) {
                        return DropdownMenuItem<int>(
                          value: b['id'] as int,
                          child: Text('${b['kode_blok']} - ${b['nama_blok']}'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedBlokId = val;
                            final match = _bloks.firstWhere((b) => b['id'] == val);
                            _selectedBlokKode = match['kode_blok'] ?? 'Blok';
                          });
                        }
                      },
                    ),

                  const SizedBox(height: 16),

                  // Baris / Bedengan
                  const Text(
                    'Nomor Baris / Bedengan',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AgriColors.textDark),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _barisController,
                    decoration: InputDecoration(
                      hintText: 'Contoh: Baris 3 Bedengan 2',
                      prefixIcon: const Icon(Icons.format_list_numbered, color: AgriColors.primary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Jenis Masalah Dropdown
                  const Text(
                    'Kategori Masalah',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AgriColors.textDark),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _jenisMasalah,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      prefixIcon: const Icon(Icons.category_outlined, color: AgriColors.primary),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: _jenisOptions.map((opt) {
                      return DropdownMenuItem(value: opt, child: Text(opt));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _jenisMasalah = val;
                          _filterMasterItem();
                        });
                      }
                    },
                  ),

                  // Pilihan Cepat dari Master Data Dukung Hama & Penyakit
                  if (matchingMaster.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Pilih Cepat dari Master Data Dukung ($_jenisMasalah)',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AgriColors.primary),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      initialValue: _selectedMasterItem?['id'] as int?,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        prefixIcon: const Icon(Icons.pest_control_outlined, color: AgriColors.chiliRed),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: matchingMaster.map((m) {
                        return DropdownMenuItem<int>(
                          value: m['id'] as int,
                          child: Text(
                            m['nama'] ?? '',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            final picked = matchingMaster.firstWhere((m) => m['id'] == val);
                            _selectedMasterItem = picked as Map<String, dynamic>;
                            _kondisiController.text = picked['nama'] ?? '';
                            _catatanController.text = picked['solusi_pengendalian'] ?? '';
                          });
                        }
                      },
                    ),

                    if (_selectedMasterItem != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AgriColors.primarySubtle,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AgriColors.primaryAccent.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.info_outline, size: 16, color: AgriColors.primary),
                                const SizedBox(width: 6),
                                Text(
                                  'Gejala: ${_selectedMasterItem!['bagian_tanaman'] ?? 'Umum'}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AgriColors.primary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedMasterItem!['gejala'] ?? '',
                              style: const TextStyle(fontSize: 11, color: AgriColors.textDark),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Rekomendasi Penanganan: ${_selectedMasterItem!['solusi_pengendalian'] ?? ''}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AgriColors.primaryLight),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],

                  const SizedBox(height: 16),

                  // Jumlah Tanaman
                  const Text(
                    'Jumlah Tanaman Terdampak',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AgriColors.textDark),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _jumlahTanamanController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Contoh: 5',
                      prefixIcon: const Icon(Icons.format_list_numbered, color: AgriColors.primary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Kondisi Tanaman
                  const Text(
                    'Detail Kondisi / Gejala',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AgriColors.textDark),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _kondisiController,
                    decoration: InputDecoration(
                      hintText: 'Contoh: Daun menguning dan berkeriput',
                      prefixIcon: const Icon(Icons.warning_amber_outlined, color: AgriColors.warning),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Foto Masalah
                  const Text(
                    'Foto Bukti di Kebun',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AgriColors.textDark),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ..._photos.map(
                        (f) => Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(f, width: 75, height: 75, fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: GestureDetector(
                                onTap: () => setState(() => _photos.remove(f)),
                                child: Container(
                                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: _addPhoto,
                        child: Container(
                          width: 75,
                          height: 75,
                          decoration: BoxDecoration(
                            color: AgriColors.bg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AgriColors.border, style: BorderStyle.solid),
                          ),
                          child: const Icon(Icons.add_a_photo_outlined, color: AgriColors.primary),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Catatan / Rekomendasi
                  const Text(
                    'Catatan / Tindakan Diambil',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AgriColors.textDark),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _catatanController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Tulis tindakan penanganan atau rencana tindak lanjut...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitMasalah,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AgriColors.chiliRed,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Kirim Laporan Masalah',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
}
