import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../constants/theme.dart';
import '../services/api_service.dart';
import 'laporan_masalah_screen.dart';

/// Pilihan tile layer peta
enum _MapLayer { satellite, street }

class MonitoringKebunScreen extends StatefulWidget {
  const MonitoringKebunScreen({super.key});

  @override
  State<MonitoringKebunScreen> createState() => _MonitoringKebunScreenState();
}

class _MonitoringKebunScreenState extends State<MonitoringKebunScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  String _kebunName = 'Kebun Agrocom';
  String _kebunLokasi = 'Sambas, Kalimantan Barat';
  double _kebunLat = -0.1234;
  double _kebunLng = 109.3456;
  int _kebunRadius = 50;
  List<dynamic> _bloks = [];

  String _filterStatus = 'Semua';
  _MapLayer _mapLayer = _MapLayer.satellite;

  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadKebunData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadKebunData() async {
    setState(() => _isLoading = true);
    final res = await ApiService().getMasterLahan();

    if (res['success'] == true && res['data'] != null) {
      final kebun = res['data'];
      _kebunName = kebun['nama'] ?? 'Kebun Agrocom';
      _kebunLokasi = kebun['lokasi_text'] ?? 'Sambas, Kalimantan Barat';
      _kebunLat = double.tryParse(kebun['latitude'].toString()) ?? -0.1234;
      _kebunLng = double.tryParse(kebun['longitude'].toString()) ?? 109.3456;
      _kebunRadius = int.tryParse(kebun['radius_meter'].toString()) ?? 50;
      _bloks = kebun['bloks'] ?? [];
    } else {
      final fallback = await ApiService().getMonitoringKebun();
      if (fallback['success'] == true && fallback['data'] != null) {
        final kebun = fallback['data'];
        _kebunName = kebun['nama'] ?? 'Kebun Agrocom';
        _kebunLokasi = kebun['lokasi_text'] ?? 'Sambas, Kalimantan Barat';
        _kebunLat = double.tryParse(kebun['latitude'].toString()) ?? -0.1234;
        _kebunLng = double.tryParse(kebun['longitude'].toString()) ?? 109.3456;
        _bloks = kebun['bloks'] ?? [];
      }
    }

    setState(() => _isLoading = false);
  }

  /// Hitung posisi blok (gunakan offset jika koordinat belum diset)
  LatLng _blokLatLng(int i) {
    final b = _bloks[i] as Map<String, dynamic>;
    final blokLat = double.tryParse(b['latitude']?.toString() ?? '') ?? 0;
    final blokLng = double.tryParse(b['longitude']?.toString() ?? '') ?? 0;

    if (blokLat != 0 && blokLng != 0) {
      return LatLng(blokLat, blokLng);
    }

    final offsetFactor = (i + 1) * 0.00018;
    return LatLng(
      _kebunLat + (i.isEven ? offsetFactor : -offsetFactor),
      _kebunLng + (i % 3 == 0 ? offsetFactor : (i % 3 == 1 ? -offsetFactor : 0)),
    );
  }

  void _animateToKebun() {
    _mapController.move(LatLng(_kebunLat, _kebunLng), 18);
  }

  void _showBlokDetail(Map<String, dynamic> b) {
    final status = (b['status_kondisi'] ?? 'normal').toString().toLowerCase();
    final isDanger = status == 'masalah';
    final isWarning = status == 'perhatian';
    final badgeColor = isDanger
        ? AgriColors.danger
        : (isWarning ? AgriColors.warning : AgriColors.success);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(22),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b['kode_blok'] ?? 'Blok',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AgriColors.textDark,
                        ),
                      ),
                      Text(
                        b['nama_blok'] ?? '',
                        style: const TextStyle(fontSize: 13, color: AgriColors.textMuted),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (b['foto_kondisi'] != null &&
                  b['foto_kondisi'].toString().isNotEmpty) ...[
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    alignment: Alignment.bottomLeft,
                    children: [
                      Image.network(
                        b['foto_kondisi'].toString(),
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox.shrink(),
                      ),
                      if (b['foto_kondisi_label'] != null &&
                          b['foto_kondisi_label'].toString().isNotEmpty)
                        Container(
                          width: double.infinity,
                          color: Colors.black54,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          child: Text(
                            'Kondisi: ${b['foto_kondisi_label']}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoBadge(
                    icon: Icons.eco_outlined,
                    label: 'Tanaman',
                    value: '${b['jumlah_tanaman'] ?? 0} pohon',
                  ),
                  const SizedBox(width: 12),
                  _buildInfoBadge(
                    icon: Icons.bug_report_outlined,
                    label: 'Hama',
                    value: '${b['jumlah_hama'] ?? 0}',
                    color: (b['jumlah_hama'] ?? 0) > 0 ? AgriColors.warning : null,
                  ),
                  const SizedBox(width: 12),
                  _buildInfoBadge(
                    icon: Icons.warning_amber_outlined,
                    label: 'Masalah',
                    value: '${b['jumlah_masalah'] ?? 0}',
                    color: (b['jumlah_masalah'] ?? 0) > 0 ? AgriColors.danger : null,
                  ),
                ],
              ),
              if (b['keterangan'] != null && b['keterangan'].toString().isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AgriColors.bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AgriColors.border),
                  ),
                  child: Text(
                    'Catatan: ${b['keterangan']}',
                    style: const TextStyle(fontSize: 12, color: AgriColors.textDark),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.pest_control_outlined, color: Colors.white, size: 18),
                  label: const Text(
                    'Laporkan Masalah di Blok Ini',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AgriColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LaporanMasalahScreen(initialBlokId: b['id']),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBadge({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) {
    final effectiveColor = color ?? AgriColors.primary;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: effectiveColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: effectiveColor.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: effectiveColor, size: 20),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: AgriColors.textMuted)),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: effectiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AgriColors.bg,
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              _kebunName,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            Text(
              _kebunLokasi,
              style: const TextStyle(
                fontSize: 11,
                color: AgriColors.textMuted,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AgriColors.primary,
          labelColor: AgriColors.primary,
          unselectedLabelColor: AgriColors.textMuted,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: [
            const Tab(icon: Icon(Icons.map_outlined, size: 18), text: 'Peta Kebun'),
            Tab(
              icon: const Icon(Icons.list_alt, size: 18),
              text: 'Daftar Blok (${_bloks.length})',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [_buildMapTab(), _buildListTab()],
            ),
    );
  }

  Widget _buildMapTab() {
    // Tentukan URL tile berdasarkan pilihan layer
    final tileUrl = _mapLayer == _MapLayer.satellite
        ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

    final tileAttribution = _mapLayer == _MapLayer.satellite
        ? '© Esri, Maxar, Earthstar Geographics'
        : '© OpenStreetMap contributors';

    // Bangun marker untuk setiap blok
    final markers = <Marker>[];
    for (int i = 0; i < _bloks.length; i++) {
      final b = _bloks[i] as Map<String, dynamic>;
      final pos = _blokLatLng(i);
      final kode = b['kode_blok'] ?? 'Blok';

      markers.add(
        Marker(
          point: pos,
          width: 44,
          height: 52,
          child: GestureDetector(
            onTap: () => _showBlokDetail(b),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Text(
                    kode,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: AgriColors.textDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.location_on, color: Colors.red, size: 28),
              ],
            ),
          ),
        ),
      );

    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(_kebunLat, _kebunLng),
            initialZoom: 18,
            minZoom: 3,
            maxZoom: 20,
          ),
          children: [
            // Tile layer
            TileLayer(
              urlTemplate: tileUrl,
              userAgentPackageName: 'com.agrocom.agro.agro_mobile',
              maxZoom: 20,
            ),

            // Geofence circle
            CircleLayer(
              circles: [
                CircleMarker(
                  point: LatLng(_kebunLat, _kebunLng),
                  radius: _kebunRadius.toDouble(),
                  useRadiusInMeter: true,
                  color: Colors.green.withValues(alpha: 0.15),
                  borderColor: Colors.greenAccent,
                  borderStrokeWidth: 2,
                ),
              ],
            ),

            // Marker blok
            MarkerLayer(markers: markers),

            // Attributions
            RichAttributionWidget(
              animationConfig: const ScaleRAWA(),
              attributions: [
                TextSourceAttribution(tileAttribution),
              ],
            ),
          ],
        ),

        // Toggle tile layer (kanan atas)
        Positioned(
          top: 16,
          right: 16,
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildControlBtn(
                      icon: Icons.satellite_alt,
                      label: 'Satelit',
                      isActive: _mapLayer == _MapLayer.satellite,
                      onTap: () => setState(() => _mapLayer = _MapLayer.satellite),
                    ),
                    const Divider(height: 1),
                    _buildControlBtn(
                      icon: Icons.map_outlined,
                      label: 'Peta',
                      isActive: _mapLayer == _MapLayer.street,
                      onTap: () => setState(() => _mapLayer = _MapLayer.street),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.my_location, color: AgriColors.primary),
                  tooltip: 'Kembali ke Kebun',
                  onPressed: _animateToKebun,
                ),
              ),
            ],
          ),
        ),

        // Bottom info bar
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Radius Geofence: ${_kebunRadius}m',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AgriColors.textDark,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${_kebunLat.toStringAsFixed(5)}, ${_kebunLng.toStringAsFixed(5)}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    color: AgriColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControlBtn({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AgriColors.primarySubtle : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? AgriColors.primary : AgriColors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? AgriColors.primary : AgriColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTab() {
    final filtered = _filterStatus == 'Semua'
        ? _bloks
        : _bloks
            .where(
              (b) =>
                  (b['status_kondisi'] ?? '').toString().toLowerCase() ==
                  _filterStatus.toLowerCase(),
            )
            .toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: Colors.white,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['Semua', 'Normal', 'Perhatian', 'Masalah'].map((f) {
                final isSelected = _filterStatus == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f),
                    selected: isSelected,
                    selectedColor: AgriColors.primary,
                    backgroundColor: AgriColors.bg,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AgriColors.textDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    onSelected: (_) => setState(() => _filterStatus = f),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('Tidak ada blok dengan status ini.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) => _buildBlokCard(filtered[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildBlokCard(dynamic b) {
    final bMap = b as Map<String, dynamic>;
    final status = (bMap['status_kondisi'] ?? 'normal').toString().toLowerCase();
    final isDanger = status == 'masalah';
    final isWarning = status == 'perhatian';
    final Color badgeColor =
        isDanger ? AgriColors.danger : (isWarning ? AgriColors.warning : AgriColors.success);

    return InkWell(
      onTap: () => _showBlokDetail(bMap),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDanger
                ? AgriColors.danger.withValues(alpha: 0.3)
                : (isWarning
                    ? AgriColors.warning.withValues(alpha: 0.3)
                    : AgriColors.border),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: badgeColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      bMap['kode_blok'] ?? 'Blok',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AgriColors.textDark,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: badgeColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              bMap['nama_blok'] ?? '',
              style: const TextStyle(fontSize: 13, color: AgriColors.textMuted),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '${bMap['jumlah_tanaman'] ?? 0} Tanaman',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AgriColors.textDark,
                  ),
                ),
                const SizedBox(width: 14),
                if ((bMap['jumlah_masalah'] ?? 0) > 0) ...[
                  const Icon(Icons.error_outline, color: AgriColors.danger, size: 15),
                  const SizedBox(width: 4),
                  Text(
                    '${bMap['jumlah_masalah']} Masalah',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AgriColors.danger,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                if ((bMap['jumlah_hama'] ?? 0) > 0) ...[
                  const Icon(Icons.bug_report_outlined, color: AgriColors.warning, size: 15),
                  const SizedBox(width: 4),
                  Text(
                    '${bMap['jumlah_hama']} Hama',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AgriColors.warning,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                if ((bMap['jumlah_masalah'] ?? 0) == 0 && (bMap['jumlah_hama'] ?? 0) == 0) ...[
                  const Icon(Icons.check_circle_outline, color: AgriColors.success, size: 15),
                  const SizedBox(width: 4),
                  const Text(
                    'Subur / Normal',
                    style: TextStyle(
                      fontSize: 12,
                      color: AgriColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
