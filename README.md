# AGROCOM Mobile App (Flutter)

Aplikasi mobile untuk pekerja lapangan kebun cabai dalam mengeksekusi absensi, checklist pekerjaan, cek tanaman, pelaporan hama/penyakit, dan laporan harian.

---

## 📂 Lokasi Direktori & Android Studio
Anda dapat membuka folder ini langsung dari **Android Studio**:
- **Path**: `agro-mobile`
- **Menu Android Studio**: `File` -> `Open...` -> pilih folder `agro-mobile`.
- Menyimpan di folder `agro-mobile` **sangat aman dan normal**, tidak ada masalah sama sekali dengan build Gradle atau Android Studio.

---

## 📱 Alur Kerja Sesuai Storyboard (Screens 1 - 12)
1. **Screen 1 (Login)**: Logo Agrocom, input username `andi`, password `123456`, serta tombol konfigurasi IP server API di pojok kanan atas.
2. **Screen 2 (Dashboard)**: Info kebun "Kebun Cabai Agrocom (Sambas)", status "Hadir Masuk 07:02", 4 kartu indikator (tanaman bermasalah, laporan hama, area perlu dibersihkan, laporan masuk).
3. **Screen 3 (Absen Pagi / Masuk)**:
   - 📸 Kamera selfie perangkat langsung.
   - 📍 GPS geofencing radius kebun $\le 50$ meter dengan indikator valid hijau.
   - ⏰ Jam masuk real-time WIB.
4. **Screen 4 (Tugas Hari Ini)**: Checklist 8 tugas harian (Cek tanaman, gulma, hama, ajir, perempelan, pemupukan/penyemprotan, pembersihan, dokumentasi).
5. **Screen 5 (Cek Kondisi Tanaman)**: Pilihan kondisi Daun, Batang, Bunga, Buah + Foto dokumentasi + Catatan.
6. **Screen 6 (Laporkan Masalah Tanaman)**: Pilihan jenis masalah (Hama/Penyakit/Gulma), Lokasi (Blok A - Baris 3), jumlah tanaman terdampak, foto bukti kamera, dan catatan.
7. **Screen 7 (Laporan Harian)**: Rangkuman kondisi (gulma, hama, penyakit, ajir, perempelan, pemupukan, penyemprotan, kendala) + **Foto Sebelum & Foto Sesudah**.
8. **Screen 8 (Absen Pulang)**:
   - 📸 Foto selfie pulang.
   - 📍 GPS kebun.
   - ⏰ Jam pulang.
   - ✅ Pilihan status: *Selesai*, *Sebagian*, *Belum selesai*.
9. **Screen 10 (Monitoring Kebun)**: Peta satelit interaktif visual blok kebun (Blok A, Blok B) & list status.
10. **Screen 11 (Rekap Laporan)**: Total kehadiran 1/1, masalah tanaman, grafik kehadiran 100%.
11. **Screen 12 (Menu Admin)**: Data master, keuangan, laporan, dan logout.

---

## ⚙️ Menghubungkan Mobile App ke Backend
- **Jika Menjalankan di Android Emulator**:
  Gunakan default IP: `http://[IP_ADDRESS]/api`
- **Jika Menjalankan di HP Android Fisik**:
  Gunakan IP WiFi laptop Anda (misal `http://[IP_ADDRESS]/api`). Anda dapat mengubahnya kapan saja langsung dari tombol gerigi ⚙️ di pojok kanan atas layar Login.

---

## 🏃 Cara Menjalankan Aplikasi
```bash
cd agro-mobile
flutter run
```
Atau klik tombol **Run ▶️** di Android Studio.
