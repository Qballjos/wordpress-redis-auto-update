#!/bin/bash

# Set the path to the WordPress installation directory
WP_PATH=/var/www/html

# Check if wp-config.php exists. If not, set it up.
if [ ! -f "$WP_PATH/wp-config.php" ]; then
  echo "🧩 WordPress not found in $WP_PATH – initializing..."

  # Download the latest WordPress
  curl -o /tmp/wordpress.tar.gz https://wordpress.org/latest.tar.gz
  tar -xzf /tmp/wordpress.tar.gz -C /tmp

  # Copy WordPress files to /var/www/html
  cp -r /tmp/wordpress/* $WP_PATH
  chown -R www-data:www-data $WP_PATH

  # Modify wp-config.php to use environment variables
  cp $WP_PATH/wp-config-sample.php $WP_PATH/wp-config.php
  sed -i "s/database_name_here/$(getenv 'WORDPRESS_DB_NAME')/g" $WP_PATH/wp-config.php
  sed -i "s/username_here/$(getenv 'WORDPRESS_DB_USER')/g" $WP_PATH/wp-config.php
  sed -i "s/password_here/$(getenv 'WORDPRESS_DB_PASSWORD')/g" $WP_PATH/wp-config.php
  sed -i "s/localhost/$(getenv 'WORDPRESS_DB_HOST')/g" $WP_PATH/wp-config.php
else
  echo "✅ WordPress already exists – no need to initialize."
fi

# Check if phpinfo.php exists. If not, create it for debugging purposes.
if [ ! -f "$WP_PATH/phpinfo.php" ]; then
  echo "🔧 phpinfo.php not found – creating for debugging..."

  # Create phpinfo.php with information about the PHP setup
  echo "<?php phpinfo(); ?>" > "$WP_PATH/phpinfo.php"
  chown www-data:www-data "$WP_PATH/phpinfo.php"
fi

# Start Redis
echo "🚀 Starting Redis..."
service redis-server start

# Start Apache
echo "🚀 Starting Apache..."
apachectl -D FOREGROUND