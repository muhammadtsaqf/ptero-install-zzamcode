#!/bin/bash

set -e

######################################################################################
#                                                                                    #
# Project 'ptero-install-zzamcode'                                                   #
#                                                                                    #
# Copyright (C) 2018 - 2026, Vilhelm Prytz, <vilhelm@prytznet.se>                    #
# Modified by zzamcode                                                               #
#                                                                                    #
#   This program is free software: you can redistribute it and/or modify             #
#   it under the terms of the GNU General Public License as published by             #
#   the Free Software Foundation, either version 3 of the License, or                #
#   (at your option) any later version.                                              #
#                                                                                    #
#   This program is distributed in the hope that it will be useful,                  #
#   but WITHOUT ANY WARRANTY; without even the implied warranty of                   #
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the                    #
#   GNU General Public License for more details.                                     #
#                                                                                    #
#   You should have received a copy of the GNU General Public License                #
#   along with this program.  If not, see <https://www.gnu.org/licenses/>.           #
#                                                                                    #
# https://github.com/muhammadtsaqf/ptero-install-zzamcode/blob/main/LICENSE          #
#                                                                                    #
# This script is not associated with the official Pterodactyl Project.               #
# https://github.com/muhammadtsaqf/ptero-install-zzamcode                            #
#                                                                                    #
######################################################################################

# Check if script is loaded, load if not or fail otherwise.
fn_exists() { declare -F "$1" >/dev/null; }
if ! fn_exists lib_loaded; then
  # shellcheck source=lib/lib.sh
  source /tmp/lib.sh || source <(curl -sSL "$GITHUB_BASE_URL/$GITHUB_SOURCE"/lib/lib.sh)
  ! fn_exists lib_loaded && echo "* ERROR: Could not load lib script" && exit 1
fi

perform_update() {
  output "Memulai proses pembaruan panel..."
  
  cd /var/www/pterodactyl || exit

  output "Mematikan panel sementara (Maintenance Mode)..."
  php artisan down || true

  output "Mengunduh rilis panel terbaru..."
  curl -L -o panel.tar.gz "$PANEL_DL_URL"
  tar -xzvf panel.tar.gz
  chmod -R 755 storage/* bootstrap/cache/ 

  output "Memperbarui dependensi Composer..."
  # Tentukan PATH agar command berjalan di RHEL-based OS
  [ "$OS" == "rocky" ] || [ "$OS" == "almalinux" ] && export PATH=/usr/local/bin:$PATH
  COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader

  output "Membersihkan cache tampilan dan konfigurasi..."
  php artisan view:clear
  php artisan config:clear

  output "Menjalankan migrasi database..."
  php artisan migrate --seed --force

  output "Membuat storage symlink..."
  php artisan storage:link || true

  output "Mengembalikan izin kepemilikan file..."
  case "$OS" in
  debian | ubuntu)
    chown -R www-data:www-data /var/www/pterodactyl/*
    ;;
  rocky | almalinux)
    chown -R nginx:nginx /var/www/pterodactyl/*
    ;;
  esac

  output "Me-restart queue workers..."
  php artisan queue:restart || true

  output "Memperbarui WhatsApp Bot..."
  if ! command -v node >/dev/null 2>&1; then
    output "Menginstal Node.js untuk WhatsApp Bot..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    [ "$OS" == "ubuntu" ] || [ "$OS" == "debian" ] && apt-get install -y nodejs
    [ "$OS" == "rocky" ] || [ "$OS" == "almalinux" ] && dnf install -y nodejs
  fi
  if ! command -v pm2 >/dev/null 2>&1; then
    npm install -g pm2
  fi

  if [ -d "/var/www/pterodactyl/whatsapp-bot" ]; then
    cd /var/www/pterodactyl/whatsapp-bot
    npm install || true
    pm2 restart pterodactyl-wa-bot || pm2 start index.js --name "pterodactyl-wa-bot" || true
    pm2 save || true
    cd /var/www/pterodactyl
  fi

  output "Menghidupkan panel kembali..."
  php artisan up

  success "Panel berhasil diperbarui!"
  return 0
}

perform_update
