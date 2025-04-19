
#!/bin/bash

set -e

WP_PATH="/var/www/html"

echo "📦 Container startup initiated..."

# Install wp-cli if missing
if ! command -v wp &> /dev/null; then
  echo "🛠️ Installing wp-cli..."
  curl -s -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
  chmod +x wp-cli.phar
  mv wp-cli.phar /usr/local/bin/wp
fi

# Install WordPress if not found
if [ ! -f "$WP_PATH/wp-config.php" ]; then
  echo "🧩 Installing WordPress..."
  curl -o /tmp/wordpress.tar.gz https://wordpress.org/latest.tar.gz
  tar -xzf /tmp/wordpress.tar.gz -C /tmp
  cp -r /tmp/wordpress/* "$WP_PATH"
  chown -R www-data:www-data "$WP_PATH"

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
fi

# Wait for DB
echo "⏳ Waiting for database..."
RETRIES=20
until wp --path="$WP_PATH" core is-installed --allow-root || [ $RETRIES -eq 0 ]; do
  echo "❌ Database not ready, retrying in 5s... ($RETRIES)"
  RETRIES=$((RETRIES-1))
  sleep 5
done

# Install WordPress core if not yet installed
if ! wp --path="$WP_PATH" core is-installed --allow-root; then
  echo "⚙️ Setting up WordPress..."
  wp --path="$WP_PATH" core install     --url="${WORDPRESS_SITE_URL}"     --title="JosVisserICT"     --admin_user="${WORDPRESS_ADMIN_USER}"     --admin_password="${WORDPRESS_ADMIN_PASSWORD}"     --admin_email="${WORDPRESS_ADMIN_EMAIL}"     --skip-email     --allow-root
fi

# Set site URL
if [ -n "$WORDPRESS_SITE_URL" ]; then
  wp --path="$WP_PATH" option update siteurl "$WORDPRESS_SITE_URL" --allow-root
  wp --path="$WP_PATH" option update home "$WORDPRESS_SITE_URL" --allow-root
fi

# Start Redis in background
redis-server --daemonize yes

# Add phpinfo for debugging
if [ ! -f "$WP_PATH/phpinfo.php" ]; then
  echo "<?php phpinfo(); ?>" > "$WP_PATH/phpinfo.php"
  chown www-data:www-data "$WP_PATH/phpinfo.php"
fi

# Start Apache
echo "🚀 Starting Apache..."
exec apachectl -D FOREGROUND
