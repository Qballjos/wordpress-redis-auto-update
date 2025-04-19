WordPress Redis Auto-Update Container

Deze Docker container biedt een eenvoudige en automatische oplossing voor het beheren van een WordPress installatie met Redis-integratie. Het zorgt voor:
	•	Automatische installatie van de nieuwste versie van WordPress.
	•	Integratie van Redis voor caching en betere prestaties.
	•	PHP-optimalisatie voor WordPress, inclusief aangepaste instellingen voor uploadgrootte, uitvoertijd en geheugenlimieten.
	•	Ondersteuning voor HTTPS via Cloudflare Tunnel headers.
	•	Automatische updates via GitHub Actions, zodat je altijd up-to-date blijft met de nieuwste versies van WordPress en de container zelf.

🌟 Gebruik de container met Docker

Deze container is eenvoudig te gebruiken door de onderstaande Docker-opdracht uit te voeren. Pas de omgevingsvariabelen aan om verbinding te maken met je database en stel de URL van je WordPress-site in.

```bash
docker run -d \
  -p 8080:80 \
  -e WORDPRESS_DB_HOST=192.168.1.10 \  # IP of hostname van je database
  -e WORDPRESS_DB_NAME=wp \            # Naam van de WordPress database
  -e WORDPRESS_DB_USER=wpuser \        # Database gebruiker
  -e WORDPRESS_DB_PASSWORD=wppass \    # Database wachtwoord
  -e WORDPRESS_SITE_URL=https://jouwdomein.nl \  # URL van je WordPress site
  -v wordpress_data:/var/www/html \    # Mount persistent data
  ghcr.io/qballjos/wordpress-redis-auto-update:latest  # Gebruik de laatste versie
```


  📝 Omgevingsvariabelen

De volgende omgevingsvariabelen moeten worden ingesteld:
	•	WORDPRESS_DB_HOST: Het IP-adres of de hostnaam van je MySQL-server.
	•	WORDPRESS_DB_NAME: De naam van je WordPress-database.
	•	WORDPRESS_DB_USER: De gebruiker die toegang heeft tot de database.
	•	WORDPRESS_DB_PASSWORD: Het wachtwoord van de databasegebruiker.
	•	WORDPRESS_SITE_URL: De URL van je WordPress-site (bijvoorbeeld https://jouwdomein.nl).

📦 Persistent Data

Voor persistente data kun je /var/www/html mounten naar een Docker-volume of een Unraid share. Dit zorgt ervoor dat je WordPress-bestanden behouden blijven bij het herstarten van de container.

```bash
-v wordpress_data:/var/www/html  # Gebruik een Docker volume voor persistente data
```

🛠️ GitHub Actions

Deze container maakt gebruik van GitHub Actions voor automatische builds en updates:
	•	Push naar de main branch: Elke keer als er wijzigingen worden gepusht naar de main branch van de repository, wordt er automatisch een nieuwe Docker-image gebouwd en gepubliceerd naar de GitHub Container Registry (GHCR).
	•	Automatische updates: De container blijft altijd up-to-date met de laatste versies van WordPress en de bijbehorende afhankelijkheden.

⚙️ Werking

De container is ontworpen om:
	1.	WordPress te downloaden en te installeren.
	2.	De databaseconfiguratie automatisch toe te passen via omgevingsvariabelen.
	3.	Redis op te starten voor caching en betere prestaties.
	4.	PHP-configuraties voor optimalisatie van WordPress-instellingen aan te passen.
	5.	De site-URL en andere instellingen via wp-cli aan te passen.
	6.	De HTTPS-headers via Cloudflare Tunnel te forceren voor beveiligde verbindingen.
	7.	De container te updaten via GitHub Actions voor de nieuwste versies van WordPress en de container.

📝 Volgende stappen
	•	Clone de repository en pas de configuratie aan voor je specifieke behoeften.
	•	Push wijzigingen naar main om automatisch een nieuwe versie van de container te bouwen en te publiceren.
	•	Gebruik de container in een productieomgeving met een Cloudflare Tunnel om beveiligde HTTPS-verbindingen te garanderen.