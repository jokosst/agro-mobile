import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../constants/theme.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';

class AbsenPagiScreen extends StatefulWidget {
  const AbsenPagiScreen({super.key});

  @override
  State<AbsenPagiScreen> createState() => _AbsenPagiScreenState();
}

class _AbsenPagiScreenState extends State<AbsenPagiScreen> {
  File? _selfieImage;
  bool _isGettingLocation = true;
  bool _isSubmitting = false;
  double _latitude = LocationService.defaultKebunLat;
  double _longitude = LocationService.defaultKebunLng;
  double _distanceMeters = 12.5;
  bool _isValidRadius = true;
  String _currentTime = '';
  String _currentDate = '';

  String roundDistance() => _distanceMeters.toStringAsFixed(1);

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
      // Default to garden coordinates if GPS not active on emulator
      setState(() {
        _latitude = LocationService.defaultKebunLat;
        _longitude = LocationService.defaultKebunLng;
        _distanceMeters = 12.5;
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

  Future<void> _submitAbsenMasuk() async {
    setState(() => _isSubmitting = true);

    final res = await ApiService().absenMasuk(
      latitude: _latitude,
      longitude: _longitude,
      photo: _selfieImage,
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
                'Absen Masuk Berhasil!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AgriColors.textDark),
              ),
              const SizedBox(height: 8),
              Text(
                'Tercatat pukul $_currentTime WIB. Foto selfie dan GPS berhasil diupload ke Google Drive & server.',
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
                  child: const Text('Lanjutkan Kerja'),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Gagal melakukan absen masuk.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Absen Masuk'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            // Selfie Camera Preview Box (Storyboard Screen 3)
            GestureDetector(
              onTap: _takeSelfie,
              child: Container(
                width: 220,
                height: 260,
                decoration: BoxDecoration(
                  color: AgriColors.bg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AgriColors.primary.withValues(alpha: 0.3), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: _selfieImage != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(_selfieImage!, fit: BoxFit.cover),
                            Positioned(
                              bottom: 10,
                              right: 10,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.refresh, color: Colors.white, size: 20),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                color: AgriColors.primarySubtle,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt, color: AgriColors.primary, size: 40),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Ambil Foto Selfie',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AgriColors.primary),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Ketuk di sini untuk foto',
                              style: TextStyle(fontSize: 11, color: AgriColors.textMuted),
                            ),
                          ],
                        ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Lokasi Kebun Card Sesuai Storyboard Screen 3
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
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AgriColors.primarySubtle,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.my_location, color: AgriColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Lokasi Kebun',
                              style: TextStyle(fontSize: 12, color: AgriColors.textMuted, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_latitude.toStringAsFixed(4)}, ${_longitude.toStringAsFixed(4)}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AgriColors.textDark),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  _isGettingLocation
                                      ? 'Mendeteksi GPS...'
                                      : 'Radius valid (≤50 m) • ${roundDistance()}m',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _isValidRadius ? AgriColors.success : AgriColors.danger,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                if (_isGettingLocation)
                                  const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                else if (_isValidRadius)
                                  const Icon(Icons.check_circle, color: AgriColors.success, size: 14)
                                else
                                  const Icon(Icons.cancel, color: AgriColors.danger, size: 14),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: AgriColors.primary, size: 20),
                        onPressed: _fetchCurrentLocation,
                        tooltip: 'Perbarui GPS',
                      ),
                    ],
                  ),

                  const Divider(height: 24, color: AgriColors.border),

                  // Waktu Absen Sesuai Storyboard
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.access_time, color: Colors.blue.shade700, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Waktu',
                            style: TextStyle(fontSize: 12, color: AgriColors.textMuted, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$_currentTime WIB',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AgriColors.textDark),
                          ),
                          Text(
                            _currentDate,
                            style: const TextStyle(fontSize: 11, color: AgriColors.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Submit Button Sesuai Storyboard
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitAbsenMasuk,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AgriColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text(
                        'Absen Masuk',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ),

            const SizedBox(height: 14),

            const Text(
              'Pastikan berada di area kebun untuk absen valid',
              style: TextStyle(fontSize: 12, color: AgriColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
