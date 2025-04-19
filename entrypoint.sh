#!/bin/bash

set -e
WP_PATH="/var/www/html"

echo "📦 Container startup initiated..."

# Install WordPress if not present
if [ ! -f "$WP_PATH/wp-config.php" ]; then
  echo "🧩 WordPress niet gevonden – installatie starten..."

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
// Force HTTPS via Cloudflare
if (isset(\$_SERVER['HTTP_X_FORWARDED_PROTO']) && \$_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
  \$_SERVER['HTTPS'] = 'on';
}
EOF
fi

# Install wp-cli
if ! command -v wp &> /dev/null; then
  echo "🛠️ wp-cli niet gevonden – downloaden..."
  curl -s -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
  chmod +x wp-cli.phar
  mv wp-cli.phar /usr/local/bin/wp
fi

# Wait for DB
until wp --path="$WP_PATH" core is-installed --allow-root || mysqladmin ping -h"$WORDPRESS_DB_HOST" --silent; do
  echo "❌ Database nog niet bereikbaar, opnieuw proberen in 5s..."
  sleep 5
done

# Install WordPress if not already installed
if ! wp --path="$WP_PATH" core is-installed --allow-root; then
  wp --path="$WP_PATH" core install \
    --url="$WORDPRESS_SITE_URL" \
    --title="JosVisserICT" \
    --admin_user="${WORDPRESS_ADMIN_USER:-admin}" \
    --admin_password="${WORDPRESS_ADMIN_PASSWORD:-admin}" \
    --admin_email="${WORDPRESS_ADMIN_EMAIL:-admin@example.com}" \
    --skip-email \
    --allow-root
fi

# Update URL
if [ -n "$WORDPRESS_SITE_URL" ]; then
  wp --path="$WP_PATH" option update siteurl "$WORDPRESS_SITE_URL" --allow-root
  wp --path="$WP_PATH" option update home "$WORDPRESS_SITE_URL" --allow-root
fi

# Debug info
if [ ! -f "$WP_PATH/phpinfo.php" ]; then
  echo "<?php phpinfo(); ?>" > "$WP_PATH/phpinfo.php"
  chown www-data:www-data "$WP_PATH/phpinfo.php"
fi

echo "🚀 Redis starten..."
redis-server --daemonize yes

echo "🚀 Apache starten..."
apachectl -D FOREGROUND
