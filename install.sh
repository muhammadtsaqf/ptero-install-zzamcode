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

export GITHUB_SOURCE="main"
export SCRIPT_RELEASE="v1.3.0"
export GITHUB_BASE_URL="https://raw.githubusercontent.com/muhammadtsaqf/ptero-install-zzamcode"

LOG_PATH="/var/log/pterodactyl-installer.log"

# check for curl
if ! [ -x "$(command -v curl)" ]; then
  echo "* curl sangat dibutuhkan agar skrip ini dapat berjalan."
  echo "* silakan install menggunakan apt (Debian/Ubuntu) atau yum/dnf (CentOS/Rocky)"
  exit 1
fi

# Always remove lib.sh, before downloading it
[ -f /tmp/lib.sh ] && rm -rf /tmp/lib.sh
curl -sSL -o /tmp/lib.sh "$GITHUB_BASE_URL"/$GITHUB_SOURCE/lib/lib.sh
# shellcheck source=lib/lib.sh
source /tmp/lib.sh

# Language selection
done_lang=false
while [ "$done_lang" == false ]; do
  echo -e "\n* Please select your language / Silakan pilih bahasa Anda:"
  echo "[0] English"
  echo "[1] Bahasa Indonesia"
  echo -n "* Enter choice / Masukkan pilihan (0-1): "
  read -r lang_choice

  if [ "$lang_choice" == "0" ]; then
    export LANG_ID="en"
    MSG_WHAT_TO_DO="What would you like to do?"
    MSG_OPT_PANEL="Install Panel"
    MSG_OPT_WINGS="Install Wings"
    MSG_OPT_UPDATE="Update Panel (Frontend/UI update without reinstalling)"
    MSG_OPT_UNINSTALL="Uninstall Panel / Wings"
    MSG_INPUT_REQ="Input is required!"
    MSG_INVALID_OPT="Invalid option!"
    MSG_ENTER_CHOICE="Enter your choice"
    MSG_CONFIRM_NEXT="Installation of %s is complete. Do you want to proceed with %s? (y/N): "
    MSG_CANCEL_NEXT="Installation of %s cancelled."
    done_lang=true
  elif [ "$lang_choice" == "1" ]; then
    export LANG_ID="id"
    MSG_WHAT_TO_DO="Apa yang ingin Anda lakukan?"
    MSG_OPT_PANEL="Install Panel"
    MSG_OPT_WINGS="Install Wings"
    MSG_OPT_UPDATE="Update Panel (Pembaruan Frontend/UI tanpa instal ulang)"
    MSG_OPT_UNINSTALL="Uninstall Panel / Wings"
    MSG_INPUT_REQ="Input diperlukan!"
    MSG_INVALID_OPT="Pilihan tidak valid!"
    MSG_ENTER_CHOICE="Masukkan pilihan"
    MSG_CONFIRM_NEXT="Instalasi %s telah selesai. Apakah Anda ingin melanjutkan ke instalasi %s? (y/N): "
    MSG_CANCEL_NEXT="Instalasi %s dibatalkan."
    done_lang=true
  else
    echo -e "* Invalid option / Pilihan tidak valid!"
  fi
done

execute() {
  echo -e "\n\n* ptero-install-zzamcode $(date) \n\n" >>$LOG_PATH

  [[ "$1" == *"canary"* ]] && export GITHUB_SOURCE="main" && export SCRIPT_RELEASE="canary"
  update_lib_source
  run_ui "${1//_canary/}" |& tee -a $LOG_PATH

  if [[ -n $2 ]]; then
    # Printf to replace %s
    printf -v prompt_text "* $MSG_CONFIRM_NEXT" "$1" "$2"
    echo -e -n "$prompt_text"
    read -r CONFIRM
    if [[ "$CONFIRM" =~ [Yy] ]]; then
      execute "$2"
    else
      printf -v cancel_text "$MSG_CANCEL_NEXT" "$2"
      error "$cancel_text"
      exit 1
    fi
  fi
}

welcome ""

done=false
while [ "$done" == false ]; do
  options=(
    "$MSG_OPT_PANEL"
    "$MSG_OPT_WINGS"
    "$MSG_OPT_UPDATE"
    "$MSG_OPT_UNINSTALL"
  )

  actions=(
    "panel"
    "wings"
    "update"
    "uninstall"
  )

  output "$MSG_WHAT_TO_DO"

  for i in "${!options[@]}"; do
    output "[$i] ${options[$i]}"
  done

  echo -n "* $MSG_ENTER_CHOICE 0-$((${#actions[@]} - 1)): "
  read -r action

  [ -z "$action" ] && error "$MSG_INPUT_REQ" && continue

  valid_input=("$(for ((i = 0; i <= ${#actions[@]} - 1; i += 1)); do echo "${i}"; done)")
  [[ ! " ${valid_input[*]} " =~ ${action} ]] && error "$MSG_INVALID_OPT"
  [[ " ${valid_input[*]} " =~ ${action} ]] && done=true && IFS=";" read -r i1 i2 <<<"${actions[$action]}" && execute "$i1" "$i2"
done

# Remove lib.sh, so next time the script is run the, newest version is downloaded.
rm -rf /tmp/lib.sh
