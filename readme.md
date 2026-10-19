# Docker Stack for Laravel 13 (macOS)

A streamlined Docker configuration featuring **PHP 8.3**, **Nginx**, **MariaDB**, and **phpMyAdmin**, fine-tuned for running multiple Laravel 13 applications side by side on macOS.

---

## ⚙️ Prerequisites

1. **Docker Desktop for Mac** — download and install from [docker.com](https://www.docker.com/products/docker-desktop/). There are separate installers for **Apple Silicon (M1/M2/M3/M4)** and **Intel** Macs — pick the right one for your chip.
2. After installation, open Docker Desktop and let it finish starting up (the whale icon in the menu bar should stop animating).
3. Open **Terminal** and confirm Docker is running:

```bash
docker --version
docker compose version
```

### Recommended: Enable VirtioFS

For best file I/O performance, make sure **VirtioFS** is your file sharing implementation:

Docker Desktop → Settings (⚙️) → General → **Virtual Machine Options** → check **VirtioFS**.

This is the default on recent Docker Desktop versions, but older installations may still use gRPC FUSE which is noticeably slower.

---

## 🚀 Initial Setup

### 1. Clone This Repository

Open **Terminal** and clone the repo:

```bash
git clone -b mac <repo-url> stack
cd stack
```

### 2. Project Structure

The stack expects this layout:

```
stack/
├── docker/
│   ├── nginx/
│   │   └── conf.d/          # per-project nginx vhosts + example.conf template
│   └── php/
│       ├── Dockerfile
│       └── entrypoint.sh
├── src/                      # your Laravel projects live here, one folder each
├── docker-compose.yml
└── readme.md
```

Only `docker/nginx/example.conf` is committed — real per-project `.conf` files and everything under `src/` are project-specific and gitignored.

### 3. Build and Start

```bash
docker compose build --no-cache
docker compose up -d
```

`--no-cache` matters on first build so PHP extensions install cleanly.

> [!NOTE]
> If you're on an **Apple Silicon** Mac (M1/M2/M3/M4), the `php:8.3-fpm` and `mariadb:11` images have native `arm64` variants, so there's no emulation overhead — everything runs natively.

---

## ➕ Adding a New Project

### 1. Drop the project into `src/`

```
src/yourproject.local/
```

### 2. Nginx Configuration

Copy the example config and rename it:

```bash
cp docker/nginx/example.conf docker/nginx/conf.d/yourproject.local.conf
```

Open `docker/nginx/conf.d/yourproject.local.conf` in your editor and update `server_name` and `root` to match your project:

```nginx
server_name yourproject.local;
root /var/www/html/yourproject.local/public;
```

### 3. Hosts File (macOS)

Map the local domain to your loopback address. Open Terminal and run:

```bash
sudo nano /etc/hosts
```

Add a line at the bottom:

```
127.0.0.1   yourproject.local
```

Save (`Ctrl+O`, `Enter`) and exit (`Ctrl+X`).

**Alternative — one-liner:**

```bash
echo "127.0.0.1   yourproject.local" | sudo tee -a /etc/hosts
```

> [!NOTE]
> macOS may cache DNS. If the domain doesn't resolve after editing the hosts file, flush the DNS cache:
> ```bash
> sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder
> ```

### 4. Project `.env`

Inside `src/yourproject.local/.env`, point the database connection at the `db` **service name** — not `127.0.0.1` or `localhost`. Containers on the same Docker network don't share a loopback interface, so `127.0.0.1` from inside `app` only ever means the `app` container itself.

```env
DB_CONNECTION=mysql
DB_HOST=db
DB_PORT=3306
DB_DATABASE=yourproject
DB_USERNAME=root
DB_PASSWORD=root
```

`DB_PASSWORD` must match `MYSQL_ROOT_PASSWORD` set in `docker-compose.yml` for the `db` service — phpMyAdmin's `PMA_PASSWORD` uses the same value, which is why it logs in without prompting you.

### 5. Restart Nginx and Clear Config Cache

```bash
docker compose restart nginx
docker compose exec app bash -c "cd /var/www/html/yourproject.local && php artisan config:clear"
```

Visit `http://yourproject.local`.

---

## 🗄️ Database Access

* **From inside containers** (Laravel, artisan): `DB_HOST=db`, port `3306`
* **From the host machine** (a desktop MySQL client, TablePlus, Sequel Pro, DBeaver, etc.): `127.0.0.1`, port `3307`
* **phpMyAdmin**: `http://localhost:8080`

---

## 📄 .gitignore

```gitignore
# Per-project nginx vhosts — keep only the template
docker/nginx/conf.d/*.conf
!docker/nginx/conf.d/example.conf.template

# Project source — clone/pull projects separately, don't commit them here
src/*
!src/.gitkeep

# IDE settings
.idea
```

---

## ⚠️ macOS-Specific Troubleshooting

### Port 80 Already in Use

macOS may have **AirPlay Receiver** listening on port 80 (on Monterey and later):

System Settings → General → AirDrop & Handoff → **AirPlay Receiver** → turn it off.

Alternatively, change the nginx port mapping in `docker-compose.yml` from `"80:80"` to e.g. `"8000:80"`.

### Slow File I/O / Performance

If pages load slowly, especially on projects with large `vendor/` or `node_modules/` directories:

1. Make sure **VirtioFS** is enabled (see Prerequisites above).
2. Run `composer install` inside the container so `vendor/` lives on the container's filesystem:
   ```bash
   docker compose exec app bash -c "cd /var/www/html/yourproject.local && composer install"
   ```
3. Apple Silicon Macs generally perform better than Intel Macs with Docker Desktop.

### Permission Issues

Docker Desktop for Mac handles file permission mapping automatically through its VM layer. If you hit permission errors on `storage/` or `bootstrap/cache/`, the entrypoint script should have fixed them on container start. You can also fix them manually:

```bash
docker compose exec app bash -c "cd /var/www/html/yourproject.local && chown -R www-data:www-data storage bootstrap/cache && chmod -R 775 storage bootstrap/cache"
```

---

## 🔧 Notes

* PHP extensions installed: `pdo_mysql`, `mbstring`, `exif`, `pcntl`, `bcmath`, `gd` (with jpeg/freetype support), `zip`, `intl`, `opcache`.
* `opcache.validate_timestamps=1` is set for local dev so file changes show up without a container restart. For a production/VPS build, switch this to `0` for full opcache performance.
* `client_max_body_size 64M;` is set in the nginx template to match PHP's `upload_max_filesize`/`post_max_size` — without it, nginx rejects large uploads before they even reach PHP, regardless of the PHP-side limits.
* `entrypoint.sh` only `chown`/`chmod`s each project's `storage/` and `bootstrap/cache/` on container start, not the whole `src/` tree — keeps startup fast as you add more projects.
* No `.env` file is needed in the stack root on macOS — the UID/GID user mapping used on Linux is not required because Docker Desktop handles file permissions through its VM file sharing layer.
