#!/bin/bash

set -e

######################################################################################
#                                                                                    #
# Project 'ptero-install-zzamcode'                                                   #
#                                                                                    #
# Copyright (C) 2018 - 2026, Vilhelm Prytz, <vilhelm@prytznet.se>                    #
# Modified by Zzamcode                                                               #
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

main() {
  welcome "Update Panel"

  if [ ! -d "/var/www/pterodactyl" ]; then
    error "Pterodactyl panel tidak ditemukan di /var/www/pterodactyl!"
    exit 1
  fi

  warning "Proses ini akan mengunduh versi terbaru panel dan menimpa file yang ada."
  warning "Pastikan Anda sudah melakukan BACKUP database dan file panel sebelum melanjutkan."
  
  echo -e -n "* Apakah Anda yakin ingin melanjutkan proses pembaruan panel? (y/N): "
  read -r CONFIRM
  if [[ "$CONFIRM" =~ [Yy] ]]; then
    run_installer "update"
  else
    error "Pembaruan panel dibatalkan."
    exit 1
  fi
}

goodbye() {
  print_brake 62
  output "Proses pembaruan panel telah selesai!"
  output "Panel Anda seharusnya sudah berjalan dengan versi yang terbaru."
  print_brake 62
}

main
goodbye
