#!/bin/bash

set -e

WP_PATH="/var/www/html"
echo "📦 Container startup initiated..."

# Install wp-cli if not available
if ! command -v wp &> /dev/null; then
  echo "🛠️ wp-cli not found – installing..."
  curl -s -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
  chmod +x wp-cli.phar
  mv wp-cli.phar /usr/local/bin/wp
fi

# Set environment fallbacks for CLI context
export HTTP_HOST="${WORDPRESS_SITE_URL#https://}"
export SERVER_NAME="$HTTP_HOST"

# Download and configure WordPress
if [ ! -f "$WP_PATH/wp-config.php" ]; then
  echo "🧩 WordPress not found – setting up..."

  curl -o /tmp/wordpress.tar.gz https://wordpress.org/latest.tar.gz
  tar -xzf /tmp/wordpress.tar.gz -C /tmp
  cp -r /tmp/wordpress/* "$WP_PATH"
  chown -R www-data:www-data "$WP_PATH"

  echo "🔧 Configuring wp-config.php..."
  cp "$WP_PATH/wp-config-sample.php" "$WP_PATH/wp-config.php"

  sed -i "s/database_name_here/${WORDPRESS_DB_NAME}/g" "$WP_PATH/wp-config.php"
  sed -i "s/username_here/${WORDPRESS_DB_USER}/g" "$WP_PATH/wp-config.php"
  sed -i "s/password_here/${WORDPRESS_DB_PASSWORD}/g" "$WP_PATH/wp-config.php"
  sed -i "s/localhost/${WORDPRESS_DB_HOST}/g" "$WP_PATH/wp-config.php"

  cat <<EOF >> "$WP_PATH/wp-config.php"

// Force HTTPS behind proxy like Cloudflare Tunnel
if (isset(\$_SERVER['HTTP_X_FORWARDED_PROTO']) && \$_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
    \$_SERVER['HTTPS'] = 'on';
}
EOF
else
  echo "✅ WordPress already exists – skipping setup."
fi

# Wait for database to be ready
echo "⏳ Waiting for database to become available..."
RETRIES=20
until wp --path="$WP_PATH" db check --allow-root >/dev/null 2>&1 || [ $RETRIES -eq 0 ]; do
  echo "❌ Database not reachable, retrying in 5s... ($RETRIES)"
  sleep 5
  RETRIES=$((RETRIES - 1))
done

if [ $RETRIES -eq 0 ]; then
  echo "🚫 Could not connect to the database – exiting."
  exit 1
fi

# Install WordPress if not already installed
if ! wp --path="$WP_PATH" core is-installed --allow-root; then
  echo "📦 Installing WordPress..."

  wp --path="$WP_PATH" core install \
    --url="$WORDPRESS_SITE_URL" \
    --title="${WORDPRESS_TITLE:-JosVisserICT}" \
    --admin_user="${WORDPRESS_ADMIN_USER:-admin}" \
    --admin_password="${WORDPRESS_ADMIN_PASSWORD:-admin}" \
    --admin_email="${WORDPRESS_ADMIN_EMAIL:-admin@example.com}" \
    --skip-email \
    --allow-root
else
  echo "✅ WordPress is already installed in the database."
fi

# Update site URL (optional)
if [ -n "$WORDPRESS_SITE_URL" ]; then
  echo "🔗 Updating WordPress site URL: $WORDPRESS_SITE_URL"
  wp --path="$WP_PATH" option update siteurl "$WORDPRESS_SITE_URL" --allow-root
  wp --path="$WP_PATH" option update home "$WORDPRESS_SITE_URL" --allow-root
fi

# Create phpinfo file for debugging
if [ ! -f "$WP_PATH/phpinfo.php" ]; then
  echo "<?php phpinfo(); ?>" > "$WP_PATH/phpinfo.php"
  chown www-data:www-data "$WP_PATH/phpinfo.php"
  echo "🔧 Created phpinfo.php"
fi

# Set PHP limits
PHP_CUSTOM_INI="/etc/php/8.3/apache2/conf.d/30-custom.ini"
echo "upload_max_filesize = 128M" > "$PHP_CUSTOM_INI"
echo "post_max_size = 64M" >> "$PHP_CUSTOM_INI"
echo "max_execution_time = 300" >> "$PHP_CUSTOM_INI"
echo "memory_limit = 512M" >> "$PHP_CUSTOM_INI"

# Start Redis
echo "🚀 Starting Redis..."
redis-server --daemonize yes || echo "⚠️ Redis start failed or already running."

# Start Apache
echo "🚀 Starting Apache..."
exec apachectl -D FOREGROUND