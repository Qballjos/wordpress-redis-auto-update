# WordPress + Redis Docker Setup (zonder DB)

Deze setup draait WordPress en Redis in Docker containers. De database draait al extern, dus deze container verbindt enkel via omgeving variabelen.

## 📦 Inhoud

- WordPress (laatste versie)
- Redis (laatste versie)
- Geen MySQL: je eigen DB-container wordt gebruikt

## 🚀 Starten

1. Pas `.env` aan met jouw database-gegevens
2. Start containers:
   ```bash
   docker-compose up -d