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
export LANG_ID="en"
MSG_WHAT_TO_DO="What would you like to do?"
MSG_OPT_PANEL="Install Panel"
MSG_OPT_WINGS="Install Wings"
MSG_OPT_UPDATE="Update Panel (Frontend/UI update without reinstalling)"
MSG_OPT_UNINSTALL="Uninstall Panel / Wings"
MSG_OPT_PHPMYADMIN="Install phpMyAdmin & Configure DB Host"
MSG_INPUT_REQ="Input is required!"
MSG_INVALID_OPT="Invalid option!"
MSG_ENTER_CHOICE="Enter your choice"
MSG_CONFIRM_NEXT="Installation of %s is complete. Do you want to proceed with %s? (y/N): "
MSG_CANCEL_NEXT="Installation of %s cancelled."

install_phpmyadmin() {
  echo "* --------------------------------------------------"
  echo "* Installing phpMyAdmin and MariaDB-Server..."
  echo "* --------------------------------------------------"
  apt update
  apt install -y mariadb-server phpmyadmin
  
  echo ""
  echo "* Let's configure the Database Host account."
  read -p "* Enter Database Username [panel_db_user]: " DB_USER
  DB_USER=${DB_USER:-panel_db_user}
  
  read -p "* Enter Database Password [randomly generated]: " DB_PASS
  if [ -z "$DB_PASS" ]; then
    DB_PASS=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 16 ; echo '')
    echo "* Generated Password: $DB_PASS"
  fi
  
  echo "* Creating Database User for Pterodactyl Host..."
  mysql -u root -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'127.0.0.1' IDENTIFIED BY '${DB_PASS}';"
  mysql -u root -e "ALTER USER '${DB_USER}'@'127.0.0.1' IDENTIFIED BY '${DB_PASS}';"
  mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO '${DB_USER}'@'127.0.0.1' WITH GRANT OPTION;"
  mysql -u root -e "FLUSH PRIVILEGES;"
  
  echo "* Automating Pterodactyl Database Host Setup..."
  if [ -d "/var/www/pterodactyl" ]; then
    cd /var/www/pterodactyl
    php artisan p:database-host:make \
      --name="Localhost MySQL (phpMyAdmin)" \
      --host="127.0.0.1" \
      --port="3306" \
      --username="${DB_USER}" \
      --password="${DB_PASS}" \
      --no-interaction
    echo "* --------------------------------------------------"
    echo "* phpMyAdmin and Database Host successfully configured!"
    echo "* --------------------------------------------------"
  else
    echo "* Pterodactyl Panel is not installed at /var/www/pterodactyl!"
    echo "* Please install the Panel first."
  fi
}

execute() {
  echo -e "\n\n* ptero-install-zzamcode $(date) \n\n" >>$LOG_PATH

  if [[ "$1" == "phpmyadmin" ]]; then
    install_phpmyadmin |& tee -a $LOG_PATH
    return
  fi

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
    "$MSG_OPT_PHPMYADMIN"
  )

  actions=(
    "panel"
    "wings"
    "update"
    "uninstall"
    "phpmyadmin"
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
