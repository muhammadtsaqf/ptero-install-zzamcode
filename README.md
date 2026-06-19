# :bird: ptero-install-zzamcode

[![Shellcheck](https://github.com/muhammadtsaqf/ptero-install-zzamcode/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/muhammadtsaqf/ptero-install-zzamcode/actions/workflows/shellcheck.yml)
[![License: GPL v3](https://img.shields.io/github/license/muhammadtsaqf/ptero-install-zzamcode)](LICENSE)

Skrip tidak resmi untuk menginstal Pterodactyl Panel & Wings. Mendukung versi terbaru dari Pterodactyl!

Baca lebih lanjut tentang [Pterodactyl](https://pterodactyl.io/) di sini. Skrip ini tidak terafiliasi dengan Proyek Pterodactyl resmi. Ini adalah versi modifikasi oleh **Zzamcode**.

## Fitur

- Instalasi otomatis Pterodactyl Panel (dependensi, database, cronjob, nginx).
- Instalasi otomatis Pterodactyl Wings (Docker, systemd).
- Panel: (opsional) konfigurasi otomatis Let's Encrypt.
- Panel: (opsional) konfigurasi otomatis firewall.
- Mendukung fitur uninstalasi (penghapusan) untuk panel maupun wings.

## Bantuan dan Dukungan

Skrip ini adalah versi kustomisasi dari **Zzamcode**. Jika Anda mengalami masalah terkait skrip ini dan **bukan proyek resmi Pterodactyl**, Anda dapat menghubungi tim Zzamcode.

## Instalasi yang Didukung

Daftar sistem operasi yang didukung untuk instalasi panel dan Wings menggunakan skrip ini.

### Sistem Operasi Panel dan Wings yang Didukung

| Sistem Operasi | Versi   | Dukungan           | Versi PHP |
| -------------- | ------- | ------------------ | --------- |
| Ubuntu         | 14.04   | :red_circle:       |           |
|                | 16.04   | :red_circle: \*    |           |
|                | 18.04   | :red_circle: \*    |           |
|                | 20.04   | :red_circle: \*    |           |
|                | 22.04   | :white_check_mark: | 8.3       |
|                | 24.04   | :white_check_mark: | 8.3       |
|                | 26.04   | :white_check_mark: | 8.3       |
| Debian         | 8       | :red_circle: \*    |           |
|                | 9       | :red_circle: \*    |           |
|                | 10      | :white_check_mark: | 8.3       |
|                | 11      | :white_check_mark: | 8.3       |
|                | 12      | :white_check_mark: | 8.3       |
|                | 13      | :white_check_mark: | 8.3       |
| CentOS         | 6       | :red_circle:       |           |
|                | 7       | :red_circle: \*    |           |
|                | 8       | :red_circle: \*    |           |
| Rocky Linux    | 8       | :white_check_mark: | 8.3       |
|                | 9       | :white_check_mark: | 8.3       |
| AlmaLinux      | 8       | :white_check_mark: | 8.3       |
|                | 9       | :white_check_mark: | 8.3       |

_\* Menandakan sistem operasi dan rilis yang sebelumnya didukung oleh skrip ini._

## Menggunakan Skrip Instalasi

Untuk menggunakan skrip instalasi ini, cukup jalankan perintah berikut sebagai `root`. Skrip akan bertanya apakah Anda ingin menginstal panel saja, Wings saja, atau keduanya.

```bash
bash <(curl -s https://raw.githubusercontent.com/muhammadtsaqf/ptero-install-zzamcode/main/install.sh)
```

_Catatan: Pada beberapa sistem, Anda diharuskan masuk (login) sebagai `root` terlebih dahulu sebelum menjalankan perintah satu baris ini (menggunakan `sudo` di depan perintah terkadang tidak berhasil)._

## Pengaturan Firewall

Skrip instalasi ini dapat menginstal dan mengkonfigurasi firewall secara otomatis untuk Anda. Skrip akan menanyakan apakah Anda menginginkan fitur ini atau tidak. Sangat disarankan untuk memilih pengaturan firewall otomatis.

## Kontributor ✨

Hak Cipta (C) 2018 - 2026, Vilhelm Prytz, <vilhelm@prytznet.se>, dan para kontributor!
Dimodifikasi dan dikembangkan lebih lanjut untuk komunitas oleh **Zzamcode**.
