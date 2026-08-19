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
MSG_OPT_UNINSTALL_MONGODB="Uninstall MongoDB Server & Remove Database Host"
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

  # Install MongoDB if not present
  if ! command -v mongod >/dev/null 2>&1 && ! command -v mongodb >/dev/null 2>&1; then
    echo "* Detecting OS and Package Manager for MongoDB installation..."
    
    if command -v apt-get >/dev/null 2>&1; then
      apt-get update -y
      apt-get install -y gnupg curl wget ca-certificates lsb-release || true
      
      local DISTRO=""
      if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$(echo "$ID" | tr '[:upper:]' '[:lower:]')
      fi
      
      local CODENAME=""
      if command -v lsb_release >/dev/null 2>&1; then
        CODENAME=$(lsb_release -cs 2>/dev/null || echo "")
      fi

      mkdir -p /usr/share/keyrings
      curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg --yes || true
      
      if [[ "$DISTRO" == "debian" ]]; then
        # Debian codenames: bookworm (12), bullseye (11), buster (10)
        case "$CODENAME" in
          bookworm|bullseye|buster) ;;
          *) CODENAME="bookworm" ;;
        esac
        echo "deb [ signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/debian ${CODENAME}/mongodb-org/7.0 main" | tee /etc/apt/sources.list.d/mongodb-org-7.0.list || true
      else
        # Ubuntu codenames: jammy (22.04), focal (20.04), bionic (18.04), noble (24.04 fallback to jammy)
        case "$CODENAME" in
          jammy|focal|bionic) ;;
          *) CODENAME="jammy" ;;
        esac
        echo "deb [ signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu ${CODENAME}/mongodb-org/7.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-7.0.list || true
      fi

      apt-get update -y || true
      apt-get install -y mongodb-org || apt-get install -y mongodb || true

    elif command -v dnf >/dev/null 2>&1 || command -v yum >/dev/null 2>&1; then
      local PKG_MGR="dnf"
      command -v dnf >/dev/null 2>&1 || PKG_MGR="yum"

      cat << 'EOF' > /etc/yum.repos.d/mongodb-org-7.0.repo
[mongodb-org-7.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/7.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-7.0.asc
EOF
      $PKG_MGR install -y mongodb-org || $PKG_MGR install -y mongodb-server || true

    elif command -v pacman >/dev/null 2>&1; then
      pacman -Sy --noconfirm mongodb-bin || pacman -Sy --noconfirm mongodb || true
    elif command -v zypper >/dev/null 2>&1; then
      zypper install -y mongodb || true
    fi
  fi

  # Enable and Start MongoDB service
  systemctl daemon-reload >/dev/null 2>&1 || true
  if systemctl list-unit-files 2>/dev/null | grep -q -E "^mongod\.service"; then
    systemctl enable mongod >/dev/null 2>&1 || true
    systemctl start mongod >/dev/null 2>&1 || true
  elif systemctl list-unit-files 2>/dev/null | grep -q -E "^mongodb\.service"; then
    systemctl enable mongodb >/dev/null 2>&1 || true
    systemctl start mongodb >/dev/null 2>&1 || true
  else
    systemctl enable mongod 2>/dev/null || systemctl enable mongodb 2>/dev/null || true
    systemctl start mongod 2>/dev/null || systemctl start mongodb 2>/dev/null || true
  fi

  # Ensure PHP 8.3 binary is used if available to avoid PHP 8.5/CLI version mismatches
  local PHP_BIN="php"
  if command -v php8.3 >/dev/null 2>&1; then
    PHP_BIN="php8.3"
  fi

  # Auto-detect Domain from Panel APP_URL
  local PANEL_DOMAIN=""
  if [ -f "/var/www/pterodactyl/.env" ]; then
    PANEL_DOMAIN=$(grep -E '^APP_URL=' /var/www/pterodactyl/.env | cut -d '=' -f2 | sed -E 's|https?://||' | sed -E 's|:.*||' | sed -E 's|/.*||' | tr -d '"' | tr -d "'" | tr -d ' ' || true)
  fi

  if [ -z "$PANEL_DOMAIN" ]; then
    PANEL_DOMAIN=$(curl -s http://checkip.amazonaws.com | tr -d '\n' | tr -d '\r' | tr -d ' ' || echo "127.0.0.1")
  fi

  echo "* Auto-detected Panel Domain/Host: ${PANEL_DOMAIN}"
  read -p "* Enter Domain/Host for Public Remote Database [${PANEL_DOMAIN}]: " INPUT_DOMAIN
  INPUT_DOMAIN=$(echo "$INPUT_DOMAIN" | sed -E 's|https?://||' | sed -E 's|:.*||' | sed -E 's|/.*||' | tr -d '"' | tr -d "'" | tr -d ' ' || true)
  PANEL_DOMAIN=${INPUT_DOMAIN:-$PANEL_DOMAIN}

  # Configure mongodb bindIp to 0.0.0.0 for public remote access
  if [ -f "/etc/mongod.conf" ]; then
    sed -i 's/bindIp: .*/bindIp: 0.0.0.0/' /etc/mongod.conf || true
    sed -i 's/127.0.0.1/0.0.0.0/' /etc/mongod.conf || true
  elif [ -f "/etc/mongodb.conf" ]; then
    sed -i 's/bind_ip = .*/bind_ip = 0.0.0.0/' /etc/mongodb.conf || true
    sed -i 's/127.0.0.1/0.0.0.0/' /etc/mongodb.conf || true
  fi

  # Open Firewall Port 27017 across all firewall managers
  if command -v ufw >/dev/null 2>&1; then
    ufw allow 27017/tcp || true
  fi
  if command -v firewall-cmd >/dev/null 2>&1; then
    firewall-cmd --zone=public --add-port=27017/tcp --permanent >/dev/null 2>&1 || true
    firewall-cmd --reload >/dev/null 2>&1 || true
  fi

  # Configure SELinux if enabled
  if command -v getenforce >/dev/null 2>&1 && [ "$(getenforce 2>/dev/null)" != "Disabled" ]; then
    setsebool -P mongodb_connect_any 1 2>/dev/null || true
  fi

  # Restart MongoDB Service safely without systemd noise
  if systemctl list-unit-files 2>/dev/null | grep -q -E "^mongod\.service"; then
    systemctl restart mongod >/dev/null 2>&1 || true
  elif systemctl list-unit-files 2>/dev/null | grep -q -E "^mongodb\.service"; then
    systemctl restart mongodb >/dev/null 2>&1 || true
  else
    systemctl restart mongod 2>/dev/null || systemctl restart mongodb 2>/dev/null || true
  fi

  echo "* --------------------------------------------------"
  echo "* Installing Mongo Express (MongoDB Web Control Panel GUI)..."
  echo "* --------------------------------------------------"

  # Install Node.js & npm if missing
  if ! command -v npm >/dev/null 2>&1 || ! command -v node >/dev/null 2>&1; then
    if command -v apt-get >/dev/null 2>&1; then
      curl -fsSL https://deb.nodesource.com/setup_20.x | bash - || true
      apt-get install -y nodejs || true
    elif command -v dnf >/dev/null 2>&1 || command -v yum >/dev/null 2>&1; then
      curl -fsSL https://rpm.nodesource.com/setup_20.x | bash - || true
      dnf install -y nodejs || yum install -y nodejs || true
    fi
  fi

  if command -v npm >/dev/null 2>&1; then
    mkdir -p /opt/mongo-express
    cd /opt/mongo-express
    npm install mongo-express express dotenv --no-audit --no-fund || true
    
    # Create robust config.js for Mongo Express
    cat << 'EOF' > /opt/mongo-express/config.js
module.exports = {
  mongodb: {
    server: '127.0.0.1',
    port: 27017,
    admin: true,
    auth: [],
  },
  site: {
    baseUrl: '/mongo-express/',
    cookieSecret: 'zzamcode_mongo_express_secret_key',
    sessionSecret: 'zzamcode_mongo_express_session_key',
  },
  useBasicAuth: false,
  options: {
    documentsPerPage: 10,
  },
};
EOF

    # Find Node binary path
    NODE_PATH=$(command -v node || echo "/usr/bin/node")

    # Create systemd service for Mongo Express running on port 8081
    cat << EOF > /etc/systemd/system/mongo-express.service
[Unit]
Description=Mongo Express Web GUI Control Panel
After=network.target mongod.service mongodb.service

[Service]
Type=simple
WorkingDirectory=/opt/mongo-express
Environment=ME_CONFIG_MONGODB_SERVER=127.0.0.1
Environment=ME_CONFIG_MONGODB_PORT=27017
Environment=ME_CONFIG_SITE_BASEURL=/mongo-express/
Environment=ME_CONFIG_BASICAUTH=false
Environment=PORT=8081
ExecStart=${NODE_PATH} /opt/mongo-express/node_modules/mongo-express/app.js
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload >/dev/null 2>&1 || true
    systemctl enable mongo-express >/dev/null 2>&1 || true
    systemctl restart mongo-express >/dev/null 2>&1 || true

    # Add Nginx proxy pass for /mongo-express/ if Nginx config exists
    local NGINX_CONF="/etc/nginx/sites-available/pterodactyl.conf"
    [ ! -f "$NGINX_CONF" ] && NGINX_CONF="/etc/nginx/conf.d/pterodactyl.conf"

    if [ -f "$NGINX_CONF" ]; then
      sed -i '/location \/mongo-express/d' "$NGINX_CONF" 2>/dev/null || true
      if ! grep -q "location /mongo-express/" "$NGINX_CONF"; then
        sed -i '/location \/ {/i \    location /mongo-express/ {\n        proxy_pass http://127.0.0.1:8081/;\n        proxy_http_version 1.1;\n        proxy_set_header Upgrade $http_upgrade;\n        proxy_set_header Connection "upgrade";\n        proxy_set_header Host $host;\n        proxy_cache_bypass $http_upgrade;\n    }\n' "$NGINX_CONF" || true
        systemctl reload nginx >/dev/null 2>&1 || nginx -s reload >/dev/null 2>&1 || true
      fi
    fi
  fi

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
    
    local NODE_ARG=""
    if [ -n "$NODE_ID" ] && [[ "$NODE_ID" =~ ^[0-9]+$ ]]; then
      NODE_ARG="--node=${NODE_ID}"
    fi

    cd /var/www/pterodactyl
    $PHP_BIN artisan p:database-host:make \
      --name="Public MongoDB Host" \
      --host="${PANEL_DOMAIN}" \
      --port="27017" \
      --username="root" \
      --password="mongodb_remote_secret" \
      ${NODE_ARG} \
      --no-interaction || true
  fi

  echo "* --------------------------------------------------"
  echo "* MongoDB Server successfully installed & configured for domain: ${PANEL_DOMAIN}:27017!"
  echo "* --------------------------------------------------"
}

uninstall_mongodb() {
  echo "* --------------------------------------------------"
  echo "* Uninstalling MongoDB Server, Mongo Express GUI, and Removing Panel Host..."
  echo "* --------------------------------------------------"

  # Stop and disable Mongo Express service
  systemctl stop mongo-express 2>/dev/null || true
  systemctl disable mongo-express 2>/dev/null || true
  rm -rf /etc/systemd/system/mongo-express.service /opt/mongo-express || true
  systemctl daemon-reload 2>/dev/null || true

  # Remove Nginx Mongo Express location block if present
  local NGINX_CONF="/etc/nginx/sites-available/pterodactyl.conf"
  [ ! -f "$NGINX_CONF" ] && NGINX_CONF="/etc/nginx/conf.d/pterodactyl.conf"
  if [ -f "$NGINX_CONF" ]; then
    sed -i '/location \/mongo-express/,/}/d' "$NGINX_CONF" 2>/dev/null || true
    systemctl reload nginx 2>/dev/null || true
  fi

  # Stop and disable service
  systemctl stop mongod 2>/dev/null || true
  systemctl stop mongodb 2>/dev/null || true
  systemctl disable mongod 2>/dev/null || true
  systemctl disable mongodb 2>/dev/null || true

  # Remove Packages based on OS Package Manager
  if command -v apt-get >/dev/null 2>&1; then
    apt-get purge -y mongodb-org* mongodb* || true
    apt-get autoremove -y || true
    rm -f /etc/apt/sources.list.d/mongodb* /usr/share/keyrings/mongodb* || true
  elif command -v dnf >/dev/null 2>&1 || command -v yum >/dev/null 2>&1; then
    local PKG_MGR="dnf"
    command -v dnf >/dev/null 2>&1 || PKG_MGR="yum"
    $PKG_MGR remove -y mongodb-org* mongodb-server* || true
    rm -f /etc/yum.repos.d/mongodb* || true
  fi

  # Delete config files and data directories
  rm -rf /etc/mongod.conf /etc/mongodb.conf /var/lib/mongodb /var/log/mongodb || true

  # Remove Firewall rules
  if command -v ufw >/dev/null 2>&1; then
    ufw delete allow 27017/tcp >/dev/null 2>&1 || true
  fi
  if command -v firewall-cmd >/dev/null 2>&1; then
    firewall-cmd --zone=public --remove-port=27017/tcp --permanent >/dev/null 2>&1 || true
    firewall-cmd --reload >/dev/null 2>&1 || true
  fi

  # Remove MongoDB Host and associated Databases from Pterodactyl Panel database
  if [ -d "/var/www/pterodactyl" ]; then
    echo "* Removing MongoDB Host entry from Pterodactyl Panel..."
    local PHP_BIN="php"
    if command -v php8.3 >/dev/null 2>&1; then
      PHP_BIN="php8.3"
    fi
    cd /var/www/pterodactyl
    $PHP_BIN artisan tinker --execute="\$hosts = \Pterodactyl\Models\DatabaseHost::where('port', 27017)->orWhere('name', 'LIKE', '%MongoDB%')->get(); foreach (\$hosts as \$h) { \Pterodactyl\Models\Database::where('database_host_id', \$h->id)->delete(); \$h->delete(); }" >/dev/null 2>&1 || true
  fi

  echo "* --------------------------------------------------"
  echo "* MongoDB Server and Pterodactyl Database Host completely uninstalled!"
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

  if [[ "$1" == "uninstall_mongodb" ]]; then
    uninstall_mongodb |& tee -a $LOG_PATH
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
    "$MSG_OPT_UNINSTALL_MONGODB"
  )

  actions=(
    "panel"
    "wings"
    "update"
    "uninstall"
    "phpmyadmin"
    "mongodb"
    "uninstall_mongodb"
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
