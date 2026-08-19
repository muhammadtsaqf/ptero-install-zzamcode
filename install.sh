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
MSG_OPT_MONGODB="Install & Configure MongoDB Public Remote Database Host"
MSG_INPUT_REQ="Input is required!"
MSG_INVALID_OPT="Invalid option!"
MSG_ENTER_CHOICE="Enter your choice"
MSG_CONFIRM_NEXT="Installation of %s is complete. Do you want to proceed with %s? (y/N): "
MSG_CANCEL_NEXT="Installation of %s cancelled."

install_phpmyadmin() {
  if [ ! -d "/var/www/pterodactyl" ]; then
    echo "* Pterodactyl Panel is not installed at /var/www/pterodactyl!"
    echo "* Please install the Panel first."
    return 1
  fi

  echo "* --------------------------------------------------"
  echo "* Installing phpMyAdmin and MariaDB-Server..."
  echo "* --------------------------------------------------"
  apt update
  apt install -y mariadb-server phpmyadmin php8.3-mbstring php-mbstring
  phpenmod -v 8.3 mbstring || phpenmod mbstring || true

  # Ensure PHP 8.3 binary is used if available to avoid PHP 8.5/CLI version mismatches
  local PHP_BIN="php"
  if command -v php8.3 >/dev/null 2>&1; then
    PHP_BIN="php8.3"
  fi

  # Check if a localhost Database Host already exists in Pterodactyl
  local EXISTING_HOST_ID=""
  if [ -d "/var/www/pterodactyl" ]; then
    cd /var/www/pterodactyl
    EXISTING_HOST_ID=$($PHP_BIN artisan tinker --execute="echo \Pterodactyl\Models\DatabaseHost::where('host', '127.0.0.1')->orWhere('host', 'localhost')->value('id') ?? '';" 2>/dev/null | grep -E '^[0-9]+$' | head -n 1 || true)
  fi

  if [ -n "$EXISTING_HOST_ID" ]; then
    echo ""
    echo "* Database Host 'Localhost MySQL' already exists (ID: ${EXISTING_HOST_ID})."
    echo "* Skipping database user creation to preserve existing configuration."
  else
    echo ""
    echo "* Let's configure the Database Host account."
    read -p "* Enter Database Username [panel_db_user]: " DB_USER
    DB_USER=${DB_USER:-panel_db_user}
    
    read -p "* Enter Database Password [randomly generated]: " DB_PASS
    if [ -z "$DB_PASS" ]; then
      DB_PASS=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 16 ; echo '')
      echo "* Generated Password: $DB_PASS"
    fi
    
    read -p "* Enter Node ID to link this database to [leave blank if none]: " NODE_ID
    
    echo "* Creating Database User for Pterodactyl Host..."
    mysql -u root -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASS}';"
    mysql -u root -e "ALTER USER '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASS}';"
    mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO '${DB_USER}'@'%' WITH GRANT OPTION;"
    mysql -u root -e "FLUSH PRIVILEGES;"

    if [ -d "/var/www/pterodactyl" ]; then
      cd /var/www/pterodactyl
      $PHP_BIN artisan p:database-host:make \
        --name="Localhost MySQL (phpMyAdmin)" \
        --host="127.0.0.1" \
        --port="3306" \
        --username="${DB_USER}" \
        --password="${DB_PASS}" \
        --node="${NODE_ID}" \
        --no-interaction || true
    fi
  fi
  
  echo "* Exposing phpMyAdmin to the web and configuring Auto-Login SSO..."
  if [ -d "/var/www/pterodactyl/public" ]; then
    rm -rf /var/www/pterodactyl/public/phpmyadmin
    ln -s /usr/share/phpmyadmin /var/www/pterodactyl/public/phpmyadmin
    chown -R www-data:www-data /var/www/pterodactyl/public/phpmyadmin || true
  fi

  # Create phpMyAdmin autologin.php script for Pterodactyl SSO
  cat << 'EOF' > /usr/share/phpmyadmin/autologin.php
<?php
// Clear signon loop if accessed directly via GET
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    if (session_status() === PHP_SESSION_NONE) {
        session_name('SignonSession');
        session_start();
    }
    if (isset($_SESSION['PMA_single_signon_user'])) {
        // Already authenticated, proceed to phpmyadmin index
        header('Location: index.php?route=/');
        exit;
    }
    header('Location: index.php');
    exit;
}

$user = $_POST['pma_username'] ?? $_POST['input_username'] ?? '';
$pass = $_POST['pma_password'] ?? $_POST['input_password'] ?? '';

if (!empty($user) && !empty($pass)) {
    if (session_status() === PHP_SESSION_NONE) {
        session_name('SignonSession');
        session_start();
    }
    $_SESSION['PMA_single_signon_user'] = $user;
    $_SESSION['PMA_single_signon_password'] = $pass;
    $_SESSION['PMA_single_signon_host'] = '127.0.0.1';
    $_SESSION['PMA_single_signon_port'] = '3306';
    session_write_close();

    header('Location: index.php?route=/');
    exit;
}

header('Location: index.php');
exit;
EOF
  chmod 644 /usr/share/phpmyadmin/autologin.php

  # Configure phpMyAdmin to enable signon authentication
  if [ -d "/etc/phpmyadmin/conf.d" ]; then
    cat << 'EOF' > /etc/phpmyadmin/conf.d/zzamcode-sso.inc.php
<?php
$i = 1;
$cfg['Servers'][$i]['auth_type'] = 'signon';
$cfg['Servers'][$i]['SignonSession'] = 'SignonSession';
$cfg['Servers'][$i]['SignonURL'] = '/phpmyadmin/index.php';
EOF
  fi

  echo "* --------------------------------------------------"
  echo "* phpMyAdmin and Database Host successfully configured!"
  echo "* --------------------------------------------------"
}

install_mongodb() {
  if [ ! -d "/var/www/pterodactyl" ]; then
    echo "* Pterodactyl Panel is not installed at /var/www/pterodactyl!"
    echo "* Please install the Panel first."
    return 1
  fi

  echo "* --------------------------------------------------"
  echo "* Installing MongoDB Server and configuring Remote Access..."
  echo "* --------------------------------------------------"
  apt update
  apt install -y mongodb || apt install -y mongodb-org || true
  systemctl enable mongodb || systemctl enable mongod || true
  systemctl start mongodb || systemctl start mongod || true

  # Ensure PHP 8.3 binary is used if available to avoid PHP 8.5/CLI version mismatches
  local PHP_BIN="php"
  if command -v php8.3 >/dev/null 2>&1; then
    PHP_BIN="php8.3"
  fi

  # Auto-detect Domain from Panel APP_URL
  local PANEL_DOMAIN=""
  if [ -f "/var/www/pterodactyl/.env" ]; then
    PANEL_DOMAIN=$(grep -E '^APP_URL=' /var/www/pterodactyl/.env | cut -d '=' -f2 | sed -E 's|https?://||' | sed -E 's|/.*||' | tr -d ' ' || true)
  fi

  if [ -z "$PANEL_DOMAIN" ]; then
    PANEL_DOMAIN=$(curl -s http://checkip.amazonaws.com || echo "localhost")
  fi

  echo "* Auto-detected Panel Domain/Host: ${PANEL_DOMAIN}"
  read -p "* Enter Domain/Host for Public Remote Database [${PANEL_DOMAIN}]: " INPUT_DOMAIN
  PANEL_DOMAIN=${INPUT_DOMAIN:-$PANEL_DOMAIN}

  # Configure mongodb bindIp to 0.0.0.0 for public remote access
  if [ -f "/etc/mongodb.conf" ]; then
    sed -i 's/bind_ip = .*/bind_ip = 0.0.0.0/' /etc/mongodb.conf || true
  elif [ -f "/etc/mongod.conf" ]; then
    sed -i 's/bindIp: .*/bindIp: 0.0.0.0/' /etc/mongod.conf || true
  fi

  if command -v ufw >/dev/null 2>&1; then
    ufw allow 27017/tcp || true
  fi

  systemctl restart mongodb || systemctl restart mongod || true

  # Check if MongoDB Host already exists in Pterodactyl DatabaseHosts
  local EXISTING_MONGO_HOST_ID=""
  if [ -d "/var/www/pterodactyl" ]; then
    cd /var/www/pterodactyl
    EXISTING_MONGO_HOST_ID=$($PHP_BIN artisan tinker --execute="echo \Pterodactyl\Models\DatabaseHost::where('name', 'LIKE', '%MongoDB%')->orWhere('port', 27017)->value('id') ?? '';" 2>/dev/null | grep -E '^[0-9]+$' | head -n 1 || true)
  fi

  if [ -n "$EXISTING_MONGO_HOST_ID" ]; then
    echo ""
    echo "* Database Host 'Public MongoDB Host' already exists in Panel (ID: ${EXISTING_MONGO_HOST_ID})."
  else
    echo ""
    echo "* Configuring MongoDB Database Host in Pterodactyl Panel..."
    read -p "* Enter Node ID to link this MongoDB host to [leave blank if none]: " NODE_ID
    
    cd /var/www/pterodactyl
    $PHP_BIN artisan p:database-host:make \
      --name="Public MongoDB Host" \
      --host="${PANEL_DOMAIN}" \
      --port="27017" \
      --username="root" \
      --password="mongodb_remote_secret" \
      --node="${NODE_ID}" \
      --no-interaction || true
  fi

  echo "* --------------------------------------------------"
  echo "* MongoDB Server successfully installed & configured for domain: ${PANEL_DOMAIN}:27017!"
  echo "* --------------------------------------------------"
}

execute() {
  echo -e "\n\n* ptero-install-zzamcode $(date) \n\n" >>$LOG_PATH

  if [[ "$1" == "phpmyadmin" ]]; then
    install_phpmyadmin |& tee -a $LOG_PATH
    return
  fi

  if [[ "$1" == "mongodb" ]]; then
    install_mongodb |& tee -a $LOG_PATH
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
    "$MSG_OPT_MONGODB"
  )

  actions=(
    "panel"
    "wings"
    "update"
    "uninstall"
    "phpmyadmin"
    "mongodb"
  )

  output "$MSG_WHAT_TO_DO"

  for i in "${!options[@]}"; do
    output "[$((i + 1))] ${options[$i]}"
  done

  echo -n "* $MSG_ENTER_CHOICE 1-${#actions[@]}: "
  read -r action

  [ -z "$action" ] && error "$MSG_INPUT_REQ" && continue

  valid_input=("$(for ((i = 1; i <= ${#actions[@]}; i += 1)); do echo "${i}"; done)")
  [[ ! " ${valid_input[*]} " =~ ${action} ]] && error "$MSG_INVALID_OPT" && continue
  
  index=$((action - 1))
  done=true && IFS=";" read -r i1 i2 <<<"${actions[$index]}" && execute "$i1" "$i2"
done

# Remove lib.sh, so next time the script is run the, newest version is downloaded.
rm -rf /tmp/lib.sh
