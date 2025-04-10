#!/bin/bash

set -e

WP_PATH="/var/www/html"
export PATH=$PATH:/usr/local/bin

echo "📦 Container startup initiated..."

# Wacht tot de database bereikbaar is
echo "⏳ Wachten tot de database bereikbaar is..."
until mysql -h"$WORDPRESS_DB_HOST" -u"$WORDPRESS_DB_USER" -p"$WORDPRESS_DB_PASSWORD" -e "USE $WORDPRESS_DB_NAME;" 2>/dev/null; do
  echo "❌ Database nog niet bereikbaar, opnieuw proberen in 5s..."
  sleep 5
done
echo "✅ Database connectie gelukt."

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

# Install wp-cli lokaal als het niet aanwezig is
if ! command -v wp &> /dev/null; then
  echo "🛠️ wp-cli niet gevonden – downloaden..."
  curl -s -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
  chmod +x wp-cli.phar
  mv wp-cli.phar /usr/local/bin/wp
else
  echo "✅ wp-cli al beschikbaar."
fi

# Site URL instellen via wp-cli (indien beschikbaar)
if [ -n "$WORDPRESS_SITE_URL" ]; then
  echo "🔗 Instellen WordPress URL: $WORDPRESS_SITE_URL"
  wp --path="$WP_PATH" option update siteurl "$WORDPRESS_SITE_URL" --allow-root
  wp --path="$WP_PATH" option update home "$WORDPRESS_SITE_URL" --allow-root
fi

# Controleer of WordPress al geïnstalleerd is (in de database)
if ! wp --path="$WP_PATH" core is-installed --allow-root; then
  echo "📦 WordPress is nog niet geïnstalleerd – uitvoeren van wp core install..."
  wp --path="$WP_PATH" core install \
    --url="$WORDPRESS_SITE_URL" \
    --title="${WORDPRESS_TITLE:-JosVisserICT.nl}" \
    --admin_user="${WORDPRESS_ADMIN_USER:-admin}" \
    --admin_password="${WORDPRESS_ADMIN_PASSWORD:-admin}" \
    --admin_email="${WORDPRESS_ADMIN_EMAIL:-admin@example.com}" \
    --skip-email \
    --allow-root
else
  echo "✅ WordPress database is al geïnstalleerd."
fi

# phpinfo.php maken indien gewenst
if [ ! -f "$WP_PATH/phpinfo.php" ]; then
  echo "<?php phpinfo(); ?>" > "$WP_PATH/phpinfo.php"
  chown www-data:www-data "$WP_PATH/phpinfo.php"
  echo "🔧 phpinfo.php aangemaakt."
fi

# Redis starten rechtstreeks via redis-server
echo "🚀 Redis starten rechtstreeks via redis-server..."
redis-server --daemonize yes

# Apache starten
echo "🚀 Apache starten..."
apachectl -D FOREGROUND