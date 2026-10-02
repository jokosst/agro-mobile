import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Server Host Preset
  static const String publicHost = 'https://itpos.my.id/agro';
  static const String localValetHost = 'http://agro.test';
  static const String defaultHost = publicHost;

  String _serverHost = publicHost;
  String? _token;

  String get serverHost => _serverHost;

  /// URL target efektif.
  /// Jika domain lokal .test, wajib memakai HTTP (karena port 443 Valet lokal belum secure)
  String get effectiveHost {
    var host = _serverHost;
    if (host.contains('.test') && host.startsWith('https://')) {
      host = 'http://${host.substring(8)}';
    }
    return host;
  }

  /// Endpoint dasar API:
  /// Di Android Emulator, domain lokal .test otomatis dialihkan ke gateway 10.0.2.2 (loopback Mac)
  String get baseUrl {
    final effective = effectiveHost;
    final uri = Uri.parse(effective);
    if ((uri.host == 'agro.test' || uri.host.endsWith('.test')) && Platform.isAndroid) {
      final portPart = uri.hasPort ? ':${uri.port}' : '';
      return 'http://10.0.2.2$portPart/api';
    }
    return '$effective/api';
  }

  /// Membersihkan input alamat server agar murni alamat domain/IP tanpa embel-embel '/api'
  static String cleanServerHost(String url) {
    var trimmed = url.trim();
    if (trimmed.isEmpty) return publicHost;

    // Jika domain .test (seperti agro.test), selalu gunakan http:// (port 80)
    if (trimmed.contains('.test')) {
      if (trimmed.startsWith('https://')) {
        trimmed = 'http://${trimmed.substring(8)}';
      } else if (!trimmed.startsWith('http://')) {
        trimmed = 'http://$trimmed';
      }
    } else {
      // Untuk domain publik atau IP
      if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
        final isLocal = trimmed.startsWith('localhost') ||
            trimmed.startsWith('127.0.0.1') ||
            trimmed.startsWith('10.0.2.2') ||
            trimmed.startsWith('192.168.');
        trimmed = isLocal ? 'http://$trimmed' : 'https://$trimmed';
      }

      // Jika user mengetik http:// ke domain publik (seperti itpos.my.id), arahkan ke https://
      if (trimmed.startsWith('http://') &&
          !trimmed.contains('localhost') &&
          !trimmed.contains('127.0.0.1') &&
          !trimmed.contains('10.0.2.2') &&
          !trimmed.contains('192.168.')) {
        trimmed = 'https://${trimmed.substring(7)}';
      }
    }

    // Buang trailing slash
    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }

    // Jika user sempat mengetik '/api' di akhir, otomatis buang agar hanya host murni yang tersimpan
    if (trimmed.endsWith('/api')) {
      trimmed = trimmed.substring(0, trimmed.length - 4);
    }

    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }

    return trimmed;
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedHost = prefs.getString('server_host') ?? prefs.getString('api_base_url');
    if (savedHost == null || savedHost.contains(':8000') || savedHost == 'http://agro.test') {
      _serverHost = defaultHost;
      await prefs.setString('server_host', _serverHost);
    } else {
      _serverHost = cleanServerHost(savedHost);
      await prefs.setString('server_host', _serverHost);
    }
    _token = prefs.getString('auth_token');
  }

  /// Menyimpan alamat server tujuan baru (hanya domain/host)
  Future<void> setServerHost(String newHost) async {
    _serverHost = cleanServerHost(newHost);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_host', _serverHost);
  }

  /// Alias jika dipanggil dengan setBaseUrl
  Future<void> setBaseUrl(String newUrl) => setServerHost(newUrl);

  Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> clearAuth() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
  }

  bool get isAuthenticated => _token != null;

  Map<String, String> _headers({bool isJson = true}) {
    final headers = <String, String>{
      'Accept': 'application/json',
    };
    final uri = Uri.parse(effectiveHost);
    if (uri.host == 'agro.test' || uri.host.endsWith('.test')) {
      headers['Host'] = uri.host;
    }
    if (isJson) {
      headers['Content-Type'] = 'application/json';
    }
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  /// Memproses response HTTP dan mendeteksi jika server mengembalikan HTML
  Map<String, dynamic> _handleResponse(http.Response response) {
    final body = response.body.trim();
    if (body.isEmpty) {
      return {
        'success': false,
        'message': 'Server mengembalikan respon kosong (Kode status: ${response.statusCode}).',
      };
    }

    // Deteksi jika server mengembalikan halaman HTML
    if (body.startsWith('<html') || 
        body.startsWith('<!DOCTYPE') || 
        body.startsWith('<?xml') ||
        body.toLowerCase().contains('<html')) {
      return {
        'success': false,
        'message': 'Salah alamat tujuan aplikasi: Server mengembalikan halaman Web (HTML), bukan data API JSON.\n'
            'Periksa kembali alamat server tujuan (saat ini: $_serverHost).',
      };
    }

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        if (response.statusCode >= 400 && decoded['success'] == null) {
          decoded['success'] = false;
        }
        return decoded;
      }
      return {'success': true, 'data': decoded};
    } on FormatException {
      return {
        'success': false,
        'message': 'Respon server bukan format JSON yang valid (HTTP: ${response.statusCode}). Periksa alamat server aplikasi Anda.',
      };
    }
  }

  /// Memformat pesan error koneksi menjadi bahasa yang mudah dipahami
  String _formatError(dynamic e) {
    if (e is SocketException) {
      return 'Tidak dapat terhubung ke server ($_serverHost). Pastikan server aktif dan perangkat terhubung ke jaringan yang sama.';
    }
    if (e is FormatException) {
      return 'Format data tidak sesuai. Periksa kembali alamat tujuan aplikasi ($_serverHost).';
    }
    if (e is HttpException) {
      return 'Kesalahan protokol HTTP: ${e.message}';
    }
    final str = e.toString();
    if (str.contains('FormatException') || str.contains('<html>') || str.contains('<!DOCTYPE')) {
      return 'Salah alamat tujuan aplikasi: Server mengembalikan halaman Web (HTML). '
          'Periksa kembali alamat tujuan di pengaturan (saat ini: $_serverHost).';
    }
    return 'Koneksi error: $str';
  }

  // --- AUTHENTICATION ---
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: _headers(),
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      final data = _handleResponse(response);
      if (response.statusCode == 200 && data['success'] == true) {
        await saveToken(data['token']);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', jsonEncode(data['user']));
      }
      return data;
    } catch (e) {
      return {'success': false, 'message': _formatError(e)};
    }
  }

  Future<Map<String, dynamic>> getMe() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/me'),
        headers: _headers(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': _formatError(e)};
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    required String name,
    String? email,
    String? phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/profile/update'),
        headers: _headers(),
        body: jsonEncode({
          'name': name,
          'email': email,
          'phone': phone,
        }),
      );
      final res = _handleResponse(response);
      if (res['success'] == true && res['user'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', jsonEncode(res['user']));
      }
      return res;
    } catch (e) {
      return {'success': false, 'message': _formatError(e)};
    }
  }

  Future<Map<String, dynamic>> updatePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/profile/password'),
        headers: _headers(),
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
          'new_password_confirmation': confirmPassword,
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': _formatError(e)};
    }
  }

  // --- ABSENSI ---
  Future<Map<String, dynamic>> absenMasuk({
    required double latitude,
    required double longitude,
    File? photo,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/absen/masuk'));
      request.headers.addAll(_headers(isJson: false));
      request.fields['latitude'] = latitude.toString();
      request.fields['longitude'] = longitude.toString();

      if (photo != null) {
        request.files.add(await http.MultipartFile.fromPath('foto', photo.path));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': _formatError(e)};
    }
  }

  Future<Map<String, dynamic>> absenPulang({
    required double latitude,
    required double longitude,
    required String statusPekerjaan, // selesai, sebagian, belum
    File? photo,
    String? catatan,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/absen/pulang'));
      request.headers.addAll(_headers(isJson: false));
      request.fields['latitude'] = latitude.toString();
      request.fields['longitude'] = longitude.toString();
      request.fields['status_pekerjaan'] = statusPekerjaan;
      if (catatan != null) request.fields['catatan'] = catatan;

      if (photo != null) {
        request.files.add(await http.MultipartFile.fromPath('foto', photo.path));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': _formatError(e)};
    }
  }

  Future<Map<String, dynamic>> getAbsenToday() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/absen/today'),
        headers: _headers(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': _formatError(e)};
    }
  }

  // --- TUGAS HARIAN ---
  Future<Map<String, dynamic>> getTugas() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tugas'),
        headers: _headers(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': _formatError(e)};
    }
  }

  Future<Map<String, dynamic>> toggleTugas(int id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/tugas/toggle/$id'),
        headers: _headers(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': _formatError(e)};
    }
  }

  // --- PEMERIKSAAN TANAMAN ---
  Future<Map<String, dynamic>> submitPemeriksaan({
    required String kondisiDaun,
    required String kondisiBatang,
    required String kondisiBunga,
    required String kondisiBuah,
    File? photo,
    String? catatan,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/pemeriksaan'));
      request.headers.addAll(_headers(isJson: false));
      request.fields['kondisi_daun'] = kondisiDaun;
      request.fields['kondisi_batang'] = kondisiBatang;
      request.fields['kondisi_bunga'] = kondisiBunga;
      request.fields['kondisi_buah'] = kondisiBuah;
      if (catatan != null) request.fields['catatan'] = catatan;

      if (photo != null) {
        request.files.add(await http.MultipartFile.fromPath('foto', photo.path));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': _formatError(e)};
    }
  }

  // --- LAPORAN MASALAH ---
  Future<Map<String, dynamic>> submitLaporanMasalah({
    required String jenisMasalah,
    required String baris,
    required int jumlahTanaman,
    required String kondisi,
    required List<File> photos,
    String? catatan,
    int? blokId,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/laporan-masalah'));
      request.headers.addAll(_headers(isJson: false));
      request.fields['jenis_masalah'] = jenisMasalah;
      request.fields['baris'] = baris;
      request.fields['jumlah_tanaman'] = jumlahTanaman.toString();
      request.fields['kondisi'] = kondisi;
      if (blokId != null) request.fields['blok_id'] = blokId.toString();
      if (catatan != null) request.fields['catatan'] = catatan;

      for (var file in photos) {
        request.files.add(await http.MultipartFile.fromPath('fotos[]', file.path));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': _formatError(e)};
    }
  }

  // --- LAPORAN HARIAN ---
  Future<Map<String, dynamic>> submitLaporanHarian({
    required String kondisiTanaman,
    required String gulma,
    required String hama,
    required String penyakit,
    required String ajir,
    required String perempelan,
    required String pemupukan,
    required String penyemprotan,
    String? kendala,
    File? fotoSebelum,
    File? fotoSesudah,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/laporan-harian'));
      request.headers.addAll(_headers(isJson: false));
      request.fields['kondisi_tanaman'] = kondisiTanaman;
      request.fields['gulma'] = gulma;
      request.fields['hama'] = hama;
      request.fields['penyakit'] = penyakit;
      request.fields['ajir'] = ajir;
      request.fields['perempelan'] = perempelan;
      request.fields['pemupukan'] = pemupukan;
      request.fields['penyemprotan'] = penyemprotan;
      if (kendala != null) request.fields['kendala'] = kendala;

      if (fotoSebelum != null) {
        request.files.add(await http.MultipartFile.fromPath('foto_sebelum', fotoSebelum.path));
      }
      if (fotoSesudah != null) {
        request.files.add(await http.MultipartFile.fromPath('foto_sesudah', fotoSesudah.path));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': _formatError(e)};
    }
  }

  // --- MONITORING KEBUN & REKAP ---
  Future<Map<String, dynamic>> getMonitoringKebun() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/monitoring-kebun'),
        headers: _headers(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': _formatError(e)};
    }
  }

  Future<Map<String, dynamic>> getRekapLaporan() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/rekap-laporan'),
        headers: _headers(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': _formatError(e)};
    }
  }

  // --- MASTER DATA & NOTIFIKASI ---
  Future<Map<String, dynamic>> getMasterLahan() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/master/lahan'),
        headers: _headers(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': _formatError(e)};
    }
  }

  Future<Map<String, dynamic>> getMasterDataDukung() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/master/data-dukung'),
        headers: _headers(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': _formatError(e)};
    }
  }

  Future<Map<String, dynamic>> getMasterPekerja() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/master/pekerja'),
        headers: _headers(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': _formatError(e)};
    }
  }

  Future<Map<String, dynamic>> getNotifikasi() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/notifikasi'),
        headers: _headers(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': _formatError(e)};
    }
  }
}
