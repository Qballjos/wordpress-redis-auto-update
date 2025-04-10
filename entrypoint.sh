#!/bin/bash

# Download WordPress als het nog niet bestaat
if [ ! -f /var/www/html/wp-config.php ]; then
  echo "WordPress not found - downloading..."
  curl -o /tmp/wordpress.tar.gz https://wordpress.org/latest.tar.gz
  tar -xzf /tmp/wordpress.tar.gz -C /var/www/html --strip-components=1
  chown -R www-data:www-data /var/www/html
fi

# Start Redis
service redis-server start

# Start Apache
apachectl -D FOREGROUND
