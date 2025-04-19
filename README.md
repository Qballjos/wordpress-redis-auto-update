# WordPress Redis Auto-Update Container

Een Docker container die automatisch:
- WordPress downloadt en installeert
- Redis integreert
- PHP optimaliseert
- HTTPS ondersteunt via Cloudflare Tunnel headers
- Automatisch updates pusht via GitHub Actions

## Gebruiken met Docker

```bash
docker run -d \
  -p 8080:80 \
  -e WORDPRESS_DB_HOST=192.168.1.10 \
  -e WORDPRESS_DB_NAME=wp \
  -e WORDPRESS_DB_USER=wpuser \
  -e WORDPRESS_DB_PASSWORD=wppass \
  -e WORDPRESS_SITE_URL=https://jouwdomein.nl \
  -v wordpress_data:/var/www/html \
  ghcr.io/jouwgebruikersnaam/wordpress-redis-auto-update:latest
```

## GitHub Actions

Push naar `main` → triggert build en publicatie naar GHCR.

## Persistent Data

Mount `/var/www/html` naar een Docker volume of Unraid share.
