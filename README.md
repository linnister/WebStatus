# WebStatus
Production-ready website monitoring app (PHP 8.2+, MySQL/MariaDB, optional Redis) inspired by DownDetector.

## Folder structure
- `public/` web root
- `app/controllers/` HTTP + page + API controllers
- `app/services/` checker, SSRF guard, limiter, queue, incidents, stats
- `app/templates/` server-side rendered templates
- `storage/logs/` app + worker logs
- `storage/cache/` short-lived cache and rate files
- `config/` deployment configs
- `scripts/` cron + worker scripts

## Requirements
- Ubuntu 22.04+
- Nginx + PHP-FPM (8.2+)
- MySQL 8+ or MariaDB 10.6+
- PHP extensions: `curl`, `pdo_mysql`, `mbstring`, `json`, `intl`, `redis` (optional)

## Setup
1. Copy project to server:
```bash
sudo mkdir -p /var/www/webstatus
sudo rsync -av ./ /var/www/webstatus/
```

2. Install PHP extensions:
```bash
sudo apt update
sudo apt install -y php8.2-fpm php8.2-cli php8.2-curl php8.2-mysql php8.2-mbstring php8.2-intl php8.2-redis
```

3. Configure environment:
```bash
cd /var/www/webstatus
cp .env.example .env
nano .env
```

4. Create DB and tables:
```bash
mysql -u root -p < /var/www/webstatus/database.sql
```

5. Nginx config:
- Use `nginx.conf` snippet in this repo.
- Ensure root points to `/var/www/webstatus/public`.
```bash
sudo nano /etc/nginx/sites-available/webstatus
sudo ln -s /etc/nginx/sites-available/webstatus /etc/nginx/sites-enabled/webstatus
sudo nginx -t && sudo systemctl reload nginx
```

6. Permissions:
```bash
sudo chown -R www-data:www-data /var/www/webstatus
sudo chmod -R 775 /var/www/webstatus/storage
```

## Scheduler/worker
### Option A: Cron every minute
Add crontab for `www-data`:
```bash
* * * * * /usr/bin/php /var/www/webstatus/scripts/cron_enqueue.php >> /var/www/webstatus/storage/logs/cron.log 2>&1
* * * * * /usr/bin/php /var/www/webstatus/scripts/worker.php >> /var/www/webstatus/storage/logs/worker.log 2>&1
```

### Option B: Supervisor (recommended)
1. Install supervisor
```bash
sudo apt install -y supervisor
```
2. Copy config
```bash
sudo cp /var/www/webstatus/config/supervisor-worker.conf /etc/supervisor/conf.d/webstatus-worker.conf
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl status
```
3. Keep cron for enqueue only:
```bash
* * * * * /usr/bin/php /var/www/webstatus/scripts/cron_enqueue.php >> /var/www/webstatus/storage/logs/cron.log 2>&1
```

## Routes
- `GET /` home instant check UI
- `POST /check` instant check form submit
- `GET /dashboard` monitored sites + incidents
- `GET /sites/{id}` site details + history chart
- `GET /admin` admin page (password in `.env`)
- `POST /api/check` JSON check endpoint
- `GET /api/sites` monitored sites JSON
- `GET /api/sites/{id}/history?range=24h|7d|30d`

## API curl examples
```bash
curl -X POST http://localhost/api/check -H 'Content-Type: application/json' -d '{"url":"https://example.com"}'
curl http://localhost/api/sites
curl 'http://localhost/api/sites/1/history?range=7d'
```

## Security notes
- SSRF guard blocks localhost/private/link-local/reserved targets after DNS resolution.
- Only `http`/`https`; URL credentials blocked.
- All SQL uses PDO prepared statements.
- Output escaping enabled in templates.
- Per-IP and API rate limiting with Redis (if available) and DB fallback.

## aaPanel notes
- Set website root to `/var/www/webstatus/public`.
- PHP version 8.2+.
- Add cron tasks exactly as above using aaPanel Cron UI.

## Quick health checks
```bash
php -l public/index.php
php -l scripts/worker.php
php scripts/cron_enqueue.php
php scripts/worker.php
```

