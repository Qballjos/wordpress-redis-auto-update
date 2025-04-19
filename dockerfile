FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    apache2 \
    php \
    php-mysql \
    php-cli \
    php-curl \
    php-gd \
    php-xml \
    php-mbstring \
    php-redis \
    curl \
    redis-server \
    unzip \
    less \
    nano \
    mariadb-client \
    wget \
    libapache2-mod-php \
    && rm -rf /var/lib/apt/lists/*

    RUN echo "upload_max_filesize = 128M" > /etc/php/*/apache2/conf.d/30-custom.ini && \
    echo "post_max_size = 64M" >> /etc/php/*/apache2/conf.d/30-custom.ini && \
    echo "max_execution_time = 300" >> /etc/php/*/apache2/conf.d/30-custom.ini && \
    echo "memory_limit = 512M" >> /etc/php/*/apache2/conf.d/30-custom.ini || true

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]
