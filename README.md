
# WordPress + Redis Auto-Updating Docker Container

This container is designed to automatically download, configure, and run WordPress with Redis support using environment variables.

## Features
- Ubuntu-based image with Apache, PHP 8.3, Redis
- wp-cli installation and use
- Cloudflare HTTPS proxy support
- Persistent volume for /var/www/html
- GitHub Actions CI to auto-publish image daily

## Usage (Docker / Unraid)

```yaml
environment:
  WORDPRESS_DB_NAME: wordpress
  WORDPRESS_DB_USER: wpuser
  WORDPRESS_DB_PASSWORD: secret
  WORDPRESS_DB_HOST: db:3306
  WORDPRESS_SITE_URL: https://yourdomain.com
  WORDPRESS_ADMIN_USER: admin
  WORDPRESS_ADMIN_PASSWORD: adminpass
  WORDPRESS_ADMIN_EMAIL: admin@example.com
volumes:
  - your-wordpress-data:/var/www/html
```

## Updating
This image is rebuilt daily using GitHub Actions and pushed to GHCR.
