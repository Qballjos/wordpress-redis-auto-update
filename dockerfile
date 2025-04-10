FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    apache2 \
    php \
    php-mysql \
    php-xml \
    php-mbstring \
    php-curl \
    php-gd \
    php-zip \
    php-redis \
    redis-server \
    curl \
    unzip \
    less \
    nano \
    wget \
    && apt-get clean

# Set PHP config for WordPress
RUN echo "upload_max_filesize = 256M\npost_max_size = 256M\nmemory_limit = 1G\nmax_execution_time = 300\n" > /etc/php/8.1/apache2/conf.d/99-wordpress.ini || true

# Download and extract WordPress
RUN curl -o /tmp/wordpress.tar.gz https://wordpress.org/latest.tar.gz && \
    tar -xzf /tmp/wordpress.tar.gz -C /var/www/html --strip-components=1 && \
    chown -R www-data:www-data /var/www/html

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]