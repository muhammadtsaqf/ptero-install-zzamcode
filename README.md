<div align="center">

# ⚡ Ptero Install by zzamcode

**The Ultimate Automated Installer for Pterodactyl Panel & Wings**

[![OS Support](https://img.shields.io/badge/OS-Ubuntu%20%7C%20Debian%20%7C%20AlmaLinux%20%7C%20Rocky-blue?style=for-the-badge&logo=linux)](https://pterodactyl-installer.zzam.dev)
[![PHP Version](https://img.shields.io/badge/PHP-8.3-777BB4?style=for-the-badge&logo=php)](https://pterodactyl-installer.zzam.dev)
[![Pterodactyl](https://img.shields.io/badge/Pterodactyl-v1.11+-00A6EF?style=for-the-badge&logo=pterodactyl)](https://pterodactyl-installer.zzam.dev)
[![Cloudflare CDN](https://img.shields.io/badge/CDN-Cloudflare%20Pages-F38020?style=for-the-badge&logo=cloudflare)](https://pterodactyl-installer.zzam.dev)

---

</div>

## 📌 Overview

**`ptero-install-zzamcode`** adalah skrip instalasi otomatis berkinerja tinggi untuk **Pterodactyl Panel** dan **Pterodactyl Wings**. Didesain khusus untuk menyederhanakan proses instalasi kompleks menjadi hitungan detik dengan dukungan penuh **PHP 8.3**, **WhatsApp Bot Server Management**, **Real-time PM2 Terminal**, **Cloudflare SSL**, dan **Auto-Seeded Multifungsi Egg**.

---

## 🌟 Fitur Utama & Keunggulan

### 🚀 1. One-Click Automated Deployment
- **Panel & Wings Setup**: Menginstal dependensi sistem, NGINX Web Server, MariaDB Database, Redis Cache, Composer, Pterodactyl Queue Worker, dan Systemd Services secara otomatis.
- **SSL / HTTPS Automation**: Terintegrasi langsung dengan Let's Encrypt Certbot dan Cloudflare DNS / Web server untuk sertifikat SSL gratis & terenkripsi.
- **Firewall Auto-Config**: Konfigurasi otomatis UFW (Debian/Ubuntu) dan FirewallD (RHEL/Rocky/AlmaLinux) untuk keamanan port server.

### 🤖 2. WhatsApp Bot Integration (Baileys)
- **Remote Control via WhatsApp**: Kendalikan status server (Start, Stop, Restart, Status, Stats) langsung melalui pesan WhatsApp.
- **Real-Time PM2 Log Terminal**: Monitoring log bot WhatsApp secara live dari dalam Admin UI Panel.
- **Smart Phone Matcher**: Deteksi otomatis format nomor HP (+62, 08xx, spasi) antara Database Panel dan Meta WhatsApp.

### 🧩 3. Auto-Seeded Multifungsi Egg
- **Single Egg Multi-Environment**: Egg serbaguna bawaan installer yang mendukung:
  - **Node.js**: 16, 17, 18, 19, 20, 21, 22, 23
  - **Python**: 3.9, 3.10, 3.11, 3.12, 3.13 (via Pyenv)
  - **PHP**: 7.4, 8.0, 8.1, 8.2, 8.3, 8.4
  - **Golang**: 1.21, 1.22, 1.23, 1.24
  - **Java (JDK Temurin)**: 8, 11, 17, 21
  - **Tools Bawaan**: Bun, PM2, FFmpeg, ImageMagick, Puppeteer/Chromium Headless, Redis Local, MariaDB Local, dan Cloudflare Tunnel Otomatis.

### 🔒 4. Private Panel Repository Architecture
- Panel utama disimpan dalam repository private `pterodactyl-panel-zzamcode` untuk keamanan source code.
- Build otomatis via **GitHub Actions** disinkronkan langsung ke CDN Cloudflare (`pterodactyl-installer.zzam.dev`) sehingga proses unduh selalu cepat, stabil, dan 100% terkini.

---

## 💻 Cara Menggunakan (Quick Start)

Jalankan perintah di bawah ini pada VPS berbasis Linux milik Anda (kebutuhan akses **root**):

```bash
bash <(curl -sSL https://pterodactyl-installer.zzam.dev)
```

> 💡 **Menu Pilihan Installer:**
> 1. `[0]` Install Pterodactyl Panel
> 2. `[1]` Install Pterodactyl Wings
> 3. `[2]` Install Panel & Wings (Satu VPS)
> 4. `[3]` Update Panel / Update Script
> 5. `[4]` Uninstall Pterodactyl Completely

---

## 🖥️ Sistem Operasi yang Didukung

| Sistem Operasi | Status Support | Versi PHP CLI | Catatan |
| :--- | :---: | :---: | :--- |
| **Ubuntu** 24.04 LTS (Noble Numbat) | 🟢 Recommended | PHP 8.3 | Performa & Stabilitas Terbaik |
| **Ubuntu** 22.04 LTS (Jammy Jellyfish) | 🟢 Supported | PHP 8.3 | Stabil & Teruji |
| **Debian** 12 (Bookworm) / 13 (Trixie) | 🟢 Supported | PHP 8.3 | Sangat Ringan |
| **Debian** 11 (Bullseye) | 🟢 Supported | PHP 8.3 | Stabil |
| **AlmaLinux** 9 / 8 | 🟡 Supported | PHP 8.3 | RHEL Enterprise Family |
| **Rocky Linux** 9 / 8 | 🟡 Supported | PHP 8.3 | RHEL Enterprise Family |

---

## 🌐 Kebutuhan Port & Firewall

| Port | Protokol | Fungsi | Deskripsi |
| :---: | :---: | :--- | :--- |
| **80** | TCP | HTTP Web Server | Diperlukan untuk sertifikat SSL Let's Encrypt |
| **443** | TCP | HTTPS Web Server | Akses Pterodactyl Panel UI (Encrypted) |
| **8080** | TCP | Wings HTTP API | Komunikasi antara Panel dan Daemon Wings |
| **2022** | TCP | Wings SFTP | Akses File Server via SFTP Client |

---

## 🛠️ Perintah Berguna Pasca Instalasi

Jika Anda perlu melakukan tindakan administratif setelah instalasi:

```bash
# Membuat akun Administrator baru
php /var/www/pterodactyl/artisan ptero:user

# Menjalankan seeder Nest & Egg manual
php /var/www/pterodactyl/artisan db:seed --class=NestSeeder
php /var/www/pterodactyl/artisan db:seed --class=EggSeeder

# Restart Queue Worker Panel
systemctl restart pteroq.service

# Restart Wings Daemon
systemctl restart wings
```

---

## 📜 Lisensi & Kredit

- **Project Core**: Dikembangkan berbasis `pterodactyl-installer` oleh **Vilhelm Prytz** dan para kontributor open-source.
- **Custom Enhancements & Maintainer**: Dimodifikasi & Dikembangkan oleh **zzamcode** ([@muhammadtsaqf](https://github.com/muhammadtsaqf)).
- **Lisensi**: Distributed under the [GNU General Public License v3.0](LICENSE).

<div align="center">
  <p>Made with ❤️ by <b>zzamcode</b> for the Server Administration Community.</p>
</div>
