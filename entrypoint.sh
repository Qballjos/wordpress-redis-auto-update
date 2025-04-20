#!/bin/bash

set -e

WP_PATH="/var/www/html"

echo "📦 Container startup initiated..."

# 📦 WordPress downloaden/installeren als het nog niet aanwezig is
if [ ! -f "$WP_PATH/wp-config.php" ]; then
  echo "🧩 WordPress niet gevonden in $WP_PATH – installatie starten..."

  curl -o /tmp/wordpress.tar.gz https://wordpress.org/latest.tar.gz
  tar -xzf /tmp/wordpress.tar.gz -C /tmp
  cp -r /tmp/wordpress/* "$WP_PATH"
  chown -R www-data:www-data "$WP_PATH"

  echo "🔧 wp-config.php configureren..."

  cp "$WP_PATH/wp-config-sample.php" "$WP_PATH/wp-config.php"
  sed -i "s/database_name_here/${WORDPRESS_DB_NAME}/g" "$WP_PATH/wp-config.php"
  sed -i "s/username_here/${WORDPRESS_DB_USER}/g" "$WP_PATH/wp-config.php"
  sed -i "s/password_here/${WORDPRESS_DB_PASSWORD}/g" "$WP_PATH/wp-config.php"
  sed -i "s/localhost/${WORDPRESS_DB_HOST}/g" "$WP_PATH/wp-config.php"

  # HTTPS forceren via Cloudflare headers
  cat <<EOF >> "$WP_PATH/wp-config.php"

// Force HTTPS behind proxy like Cloudflare Tunnel
if (isset(\$_SERVER['HTTP_X_FORWARDED_PROTO']) && \$_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
    \$_SERVER['HTTPS'] = 'on';
}
EOF
else
  echo "✅ WordPress already exists – skipping setup."
fi

# 🛠️ wp-cli installeren indien nodig
if ! command -v wp &> /dev/null; then
  echo "🛠️ wp-cli not found – installing..."
  curl -s -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
  chmod +x wp-cli.phar
  mv wp-cli.phar /usr/local/bin/wp
else
  echo "✅ wp-cli is already available."
fi

# ⏳ Wachten op de database
echo "⏳ Waiting for database to become available..."
RETRIES=20
until wp --path="$WP_PATH" db check --allow-root > /dev/null 2>&1 || [ $RETRIES -eq 0 ]; do
  echo "❌ Database not reachable, retrying in 5s... ($RETRIES)"
  sleep 5
  RETRIES=$((RETRIES - 1))
done

# 📦 WordPress installeren als dat nog niet gedaan is
if ! wp --path="$WP_PATH" core is-installed --allow-root; then
  echo "📦 Installing WordPress..."
  wp --path="$WP_PATH" core install \
    --url="$WORDPRESS_SITE_URL" \
    --title="JosVisserICT.nl" \
    --admin_user="${WORDPRESS_ADMIN_USER:-admin}" \
    --admin_password="${WORDPRESS_ADMIN_PASSWORD:-admin}" \
    --admin_email="${WORDPRESS_ADMIN_EMAIL:-admin@example.com}" \
    --skip-email \
    --allow-root
else
  echo "✅ WordPress is already installed in the database."
fi

# 🔗 WordPress URL updaten indien opgegeven
if [ -n "$WORDPRESS_SITE_URL" ]; then
  echo "🔗 Updating WordPress site URL: $WORDPRESS_SITE_URL"
  wp --path="$WP_PATH" option update siteurl "$WORDPRESS_SITE_URL" --allow-root
  wp --path="$WP_PATH" option update home "$WORDPRESS_SITE_URL" --allow-root
fi

# 🔧 phpinfo.php maken
if [ ! -f "$WP_PATH/phpinfo.php" ]; then
  echo "<?php phpinfo(); ?>" > "$WP_PATH/phpinfo.php"
  chown www-data:www-data "$WP_PATH/phpinfo.php"
  echo "🔧 Created phpinfo.php"
fi

# 🧠 PHP configuratie optimaliseren
PHP_INI_DIR=$(php -i | grep "Scan this dir for additional .ini files" | awk -F'=> ' '{print $2}' | xargs)
echo "🔍 Geselecteerde PHP config directory: $PHP_INI_DIR"

if [ -d "$PHP_INI_DIR" ]; then
  echo "upload_max_filesize = 128M" > "$PHP_INI_DIR/30-custom.ini"
  echo "post_max_size = 64M" >> "$PHP_INI_DIR/30-custom.ini"
  echo "max_execution_time = 300" >> "$PHP_INI_DIR/30-custom.ini"
  echo "memory_limit = 512M" >> "$PHP_INI_DIR/30-custom.ini"
  echo "✅ PHP instellingen toegepast in $PHP_INI_DIR/30-custom.ini"
else
  echo "⚠️  PHP INI directory niet gevonden, overslaan."
fi

# 🚀 Redis starten
echo "🚀 Redis starten..."
redis-server --daemonize yes

# 🚀 Apache starten
echo "🚀 Apache starten..."
apachectl -D FOREGROUND