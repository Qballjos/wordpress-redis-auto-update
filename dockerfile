
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    apache2 \
    php php-mysql php-redis php-curl php-gd php-mbstring php-xml php-xmlrpc php-zip php-soap php-intl php-bcmath \
    curl less unzip wget redis-server mariadb-client \
    libapache2-mod-php \
    && apt-get clean

# Enable Apache mods
RUN a2enmod rewrite headers

# Configure PHP for WordPress
RUN PHP_DIR=$(find /etc/php -type d -name apache2) && \
    echo "upload_max_filesize = 64M" > $PHP_DIR/conf.d/30-custom.ini && \
    echo "post_max_size = 64M" >> $PHP_DIR/conf.d/30-custom.ini && \
    echo "max_execution_time = 300" >> $PHP_DIR/conf.d/30-custom.ini

# Copy entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Create necessary directories
RUN mkdir -p /var/www/html
VOLUME /var/www/html

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]
