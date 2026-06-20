<div align="center">
  <h1>✨ Ptero Install by zzamcode ✨</h1>
  <p><b>Skrip Instalasi Otomatis Pterodactyl Panel & Wings Terkeren se-Dunia!</b></p>
</div>

---

## 🚀 Apa itu `ptero-install-zzamcode`?
Ini bukan sembarang skrip instalasi! Ini adalah versi modifikasi super canggih dari skrip instalasi Pterodactyl resmi. Dibangun khusus untuk memanjakan administrator server dengan fitur-fitur eksklusif yang **tidak akan Anda temukan di panel standar Pterodactyl**.

Semua instalasi, konfigurasi database, integrasi SSL/HTTPS, hingga pengaturan cronjob berjalan 100% secara otomatis!

## 🌟 Fitur Eksklusif (Hanya ada di versi zzamcode)

Berbeda dengan instalasi Pterodactyl biasa, panel yang diinstal melalui skrip ini telah dilengkapi dengan modul rahasia kelas atas:

- 🤖 **Integrasi WhatsApp Bot Server Management (Baileys)**: Kendalikan server Anda langsung dari WhatsApp! Mulai dari `start`, `stop`, `restart`, hingga cek status server hanya lewat chat.
- 💻 **Real-Time Terminal PM2 di Admin Panel**: Pantau langsung *log* WhatsApp Bot Anda dari dalam Pterodactyl Admin UI layaknya seorang hacker sejati (Terminal Style!).
- ⚡ **Smart Phone Matching**: Sistem cerdas yang mengabaikan awalan `+`, `-`, spasi, bahkan bisa menerjemahkan `08...` ke `628...` secara otomatis antara database Panel dan WhatsApp Meta.
- 👀 **Auto-Read & Auto-Online Presence**: Bot WhatsApp tampil *Online* dan ceklis biru super responsif bagaikan CS profesional 24/7.
- 🧹 **Manajemen Sesi Bot**: Fitur Hapus Session, Start, dan Stop langsung dari antarmuka Web Panel tanpa perlu menyentuh SSH/Linux Anda sama sekali!
- 🎨 **Tampilan Installer Estetik**: Proses instalasi dihiasi dengan logo ASCII art `zzamcode` yang memanjakan mata dan warna-warni cyberpunk.

## 📦 Fitur Standar

- Instalasi otomatis **Pterodactyl Panel** (beserta dependensi, database, cronjob, dan NGINX).
- Instalasi otomatis **Pterodactyl Wings** (Docker, systemd).
- Konfigurasi otomatis Let's Encrypt (Sertifikat SSL/HTTPS gratis).
- Konfigurasi otomatis Firewall (UFW / FirewallD).
- Fitur uninstalasi total jika Anda ingin menghapus semuanya.

---

## 🛠️ Cara Menggunakan Skrip Instalasi

Pastikan Anda *login* ke VPS Anda menggunakan akses **root** (jalankan `sudo su` jika belum). Lalu cukup *copy-paste* mantra sakti di bawah ini:

```bash
bash <(curl -s https://raw.githubusercontent.com/muhammadtsaqf/ptero-install-zzamcode/main/install.sh)
```

Sistem akan otomatis memberikan menu yang interaktif dan mudah dipahami. Pilih apakah Anda ingin menginstal Panel saja, Wings saja, atau langsung Keduanya!

---

## 🖥️ Sistem Operasi yang Didukung

Demi performa maksimal dan bebas error, disarankan menggunakan sistem operasi **terbaru**.

| Sistem Operasi | Dukungan           | Keterangan Tambahan |
| -------------- | ------------------ | ------------------- |
| **Ubuntu** 22.04 / 24.04 / 26.04 | ✅ Sangat Disarankan | Menggunakan PHP 8.3 |
| **Debian** 10 / 11 / 12 / 13 | ✅ Didukung Penuh | Menggunakan PHP 8.3 |
| **Rocky Linux** 8 / 9 | ✅ Didukung Penuh | Menggunakan PHP 8.3 |
| **AlmaLinux** 8 / 9 | ✅ Didukung Penuh | Menggunakan PHP 8.3 |

*(Ubuntu 20.04 ke bawah atau CentOS 7 ke bawah sudah tidak lagi didukung demi alasan keamanan).*

---

## 🛡️ Pengaturan Firewall Otomatis
Tidak paham cara setting *Port* Linux? Tenang saja! 
Di tengah instalasi, skrip akan bertanya apakah Anda ingin mengatur firewall. **Sangat disarankan untuk memilih YA (`Y`)**. Skrip akan membuka port 80, 443 (Web) dan port Wings (8080, 2022) secara presisi dan aman.

## 🤝 Bantuan dan Dukungan
Repositori ini dikembangkan dan dirawat langsung oleh **zzamcode**. 
Jika Anda menemui *bug* keren atau masalah teknis terkait instalasi bot ini, jangan sungkan untuk membuka fitur **Issues** di repositori ini.

---

### 💖 Kontributor
Hak Cipta (C) 2018 - 2026, Vilhelm Prytz, dan para kontributor awal.
Dimodifikasi dengan sentuhan ajaib untuk komunitas lokal oleh **zzamcode**.

> *"Make server management feel like magic!"*
