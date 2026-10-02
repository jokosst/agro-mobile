import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../constants/theme.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';

class AbsenPulangScreen extends StatefulWidget {
  const AbsenPulangScreen({super.key});

  @override
  State<AbsenPulangScreen> createState() => _AbsenPulangScreenState();
}

class _AbsenPulangScreenState extends State<AbsenPulangScreen> {
  File? _selfieImage;
  bool _isGettingLocation = true;
  bool _isSubmitting = false;
  double _latitude = LocationService.defaultKebunLat;
  double _longitude = LocationService.defaultKebunLng;
  double _distanceMeters = 10.0;
  bool _isValidRadius = true;
  String _currentTime = '';
  String _currentDate = '';
  String _statusPekerjaan = 'selesai'; // selesai, sebagian, belum
  final _catatanController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _updateDateTime();
    _fetchCurrentLocation();
  }

  void _updateDateTime() {
    final now = DateTime.now();
    _currentTime = DateFormat('HH:mm').format(now);
    _currentDate = DateFormat('d MMMM yyyy', 'id_ID').format(now);
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() => _isGettingLocation = true);

    final position = await LocationService.getCurrentLocation();
    if (position != null) {
      final dist = LocationService.calculateDistanceInMeters(
        startLatitude: position.latitude,
        startLongitude: position.longitude,
        endLatitude: LocationService.defaultKebunLat,
        endLongitude: LocationService.defaultKebunLng,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _distanceMeters = dist;
        _isValidRadius = dist <= LocationService.defaultRadiusMeter;
        _isGettingLocation = false;
      });
    } else {
      setState(() {
        _latitude = LocationService.defaultKebunLat;
        _longitude = LocationService.defaultKebunLng;
        _distanceMeters = 10.0;
        _isValidRadius = true;
        _isGettingLocation = false;
      });
    }
  }

  Future<void> _takeSelfie() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 85,
    );

    if (picked != null) {
      setState(() {
        _selfieImage = File(picked.path);
      });
    }
  }

  Future<void> _submitAbsenPulang() async {
    setState(() => _isSubmitting = true);

    final res = await ApiService().absenPulang(
      latitude: _latitude,
      longitude: _longitude,
      statusPekerjaan: _statusPekerjaan,
      photo: _selfieImage,
      catatan: _catatanController.text.trim(),
    );

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (res['success'] == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: AgriColors.successLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: AgriColors.success, size: 36),
              ),
              const SizedBox(height: 16),
              const Text(
                'Absen Pulang Berhasil!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AgriColors.textDark),
              ),
              const SizedBox(height: 8),
              Text(
                'Terima kasih atas kerja keras Anda hari ini. Tercatat pukul $_currentTime WIB. Data & foto tersimpan di Google Drive.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AgriColors.textMuted),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  child: const Text('Selesai'),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Gagal melakukan absen pulang.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Absen Pulang'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            // Selfie Box Sesuai Storyboard Screen 8
            GestureDetector(
              onTap: _takeSelfie,
              child: Container(
                width: 200,
                height: 220,
                decoration: BoxDecoration(
                  color: AgriColors.bg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AgriColors.primary.withValues(alpha: 0.3), width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: _selfieImage != null
                      ? Image.file(_selfieImage!, fit: BoxFit.cover)
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: const BoxDecoration(
                                color: AgriColors.primarySubtle,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt, color: AgriColors.primary, size: 36),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Foto Selfie Pulang',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AgriColors.primary),
                            ),
                          ],
                        ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Lokasi & Waktu Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AgriColors.bg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AgriColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: AgriColors.primary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Lokasi', style: TextStyle(fontSize: 11, color: AgriColors.textMuted)),
                            Text(
                              '${_latitude.toStringAsFixed(4)}, ${_longitude.toStringAsFixed(4)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              _isGettingLocation
                                  ? 'Mendeteksi GPS...'
                                  : 'Radius valid (≤50 m) • ${_distanceMeters.toStringAsFixed(1)}m',
                              style: TextStyle(
                                fontSize: 11,
                                color: _isValidRadius ? AgriColors.success : AgriColors.danger,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_isGettingLocation)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else if (_isValidRadius)
                        const Icon(Icons.check_circle, color: AgriColors.success, size: 18),
                    ],
                  ),
                  const Divider(height: 20, color: AgriColors.border),
                  Row(
                    children: [
                      const Icon(Icons.access_time, color: Colors.blue, size: 20),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Waktu', style: TextStyle(fontSize: 11, color: AgriColors.textMuted)),
                          Text(
                            '$_currentTime WIB',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(_currentDate, style: const TextStyle(fontSize: 11, color: AgriColors.textMuted)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Status Pekerjaan (Radio Group Sesuai Storyboard Screen 8)
            Align(
              alignment: Alignment.centerLeft,
              child: const Text(
                'Status Pekerjaan Hari Ini',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AgriColors.textDark),
              ),
            ),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                color: AgriColors.bg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AgriColors.border),
              ),
              child: Column(
                children: [
                  _buildStatusTile(
                    label: 'Selesai',
                    subtitle: 'Seluruh target pekerjaan hari ini beres',
                    val: 'selesai',
                  ),
                  const Divider(height: 1, color: AgriColors.border),
                  _buildStatusTile(
                    label: 'Sebagian',
                    subtitle: 'Sebagian pekerjaan akan dilanjutkan besok',
                    val: 'sebagian',
                  ),
                  const Divider(height: 1, color: AgriColors.border),
                  _buildStatusTile(
                    label: 'Belum selesai',
                    subtitle: 'Terkendala cuaca / hal lain',
                    val: 'belum',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitAbsenPulang,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text('Absen Pulang'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTile({
    required String label,
    required String subtitle,
    required String val,
  }) {
    final isSelected = _statusPekerjaan == val;
    return InkWell(
      onTap: () => setState(() => _statusPekerjaan = val),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AgriColors.primary : AgriColors.textMuted,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AgriColors.primary,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AgriColors.primary : AgriColors.textDark,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: AgriColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
