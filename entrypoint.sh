#!/bin/bash

set -e

WP_PATH="/var/www/html"

echo "📦 Container startup initiated..."

# WordPress installeren als het nog niet bestaat
if [ ! -f "$WP_PATH/wp-config.php" ]; then
  echo "🧩 WordPress niet gevonden in $WP_PATH – installatie starten..."

  # Download WordPress
  curl -o /tmp/wordpress.tar.gz https://wordpress.org/latest.tar.gz
  tar -xzf /tmp/wordpress.tar.gz -C /tmp

  # Kopieer bestanden
  cp -r /tmp/wordpress/* "$WP_PATH"
  chown -R www-data:www-data "$WP_PATH"

  echo "🔧 wp-config.php configureren..."

  # wp-config instellen
  cp "$WP_PATH/wp-config-sample.php" "$WP_PATH/wp-config.php"
  sed -i "s/database_name_here/${WORDPRESS_DB_NAME}/g" "$WP_PATH/wp-config.php"
  sed -i "s/username_here/${WORDPRESS_DB_USER}/g" "$WP_PATH/wp-config.php"
  sed -i "s/password_here/${WORDPRESS_DB_PASSWORD}/g" "$WP_PATH/wp-config.php"
  sed -i "s/localhost/${WORDPRESS_DB_HOST}/g" "$WP_PATH/wp-config.php"

  # HTTPS forceren via Cloudflare header
  cat <<EOF >> "$WP_PATH/wp-config.php"

// Force HTTPS behind proxy like Cloudflare Tunnel
if (isset(\$_SERVER['HTTP_X_FORWARDED_PROTO']) && \$_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
    \$_SERVER['HTTPS'] = 'on';
}
EOF
else
  echo "✅ WordPress is al geïnstalleerd – overslaan."
fi

# Site URL instellen via wp-cli (indien beschikbaar)
if [ -n "$WORDPRESS_SITE_URL" ]; then
  echo "🔗 Instellen WordPress URL: $WORDPRESS_SITE_URL"
  wp option update siteurl "$WORDPRESS_SITE_URL" --allow-root || true
  wp option update home "$WORDPRESS_SITE_URL" --allow-root || true
fi

# phpinfo.php maken indien gewenst
if [ ! -f "$WP_PATH/phpinfo.php" ]; then
  echo "<?php phpinfo(); ?>" > "$WP_PATH/phpinfo.php"
  chown www-data:www-data "$WP_PATH/phpinfo.php"
  echo "🔧 phpinfo.php aangemaakt."
fi

# Redis starten
echo "🚀 Redis starten..."
service redis-server start

# Apache starten
echo "🚀 Apache starten..."
apachectl -D FOREGROUND