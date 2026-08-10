# Docker Stack for Laravel 13 (Ubuntu / Linux)

A streamlined Docker configuration featuring **PHP 8.3**, **Nginx**, **MariaDB**, and **phpMyAdmin**, fine-tuned for running multiple Laravel 13 applications side by side on Ubuntu.

---

## 🚀 Initial Setup

### 1. Create Required Directories

The stack expects this structure at the project root:

```
stack/
├── docker/
│   ├── nginx/
│   │   └── conf.d/          # per-project nginx vhosts + example.conf.template
│   └── php/
│       ├── Dockerfile
│       └── entrypoint.sh
├── src/                      # your Laravel projects live here, one folder each
├── docker-compose.yml
└── .env                       # host UID/GID for the app container (see below)
```

Only `docker/nginx/conf.d/example.conf.template` is committed to this repo — real per-project `.conf` files and everything under `src/` are project-specific and gitignored (see `.gitignore` section below).

### 2. Set Your Host UID/GID

The `app` container maps `www-data` to your host user's UID/GID, so files created by the container (via `storage/`, `bootstrap/cache/`, artisan commands, etc.) aren't owned by a mismatched user when you edit them from your IDE outside the container.

Create `.env` in the stack root:

```env
UID=1000
GID=1000
```

Confirm your actual values with `id -u` and `id -g` — on a single-user Ubuntu install they're almost always `1000:1000`, but check before assuming.

### 3. Configure Your Project Name

The default project name is `stack`. To rename it, update `docker-compose.yml`:

* Rename `container_name` for each service (e.g. `stack_app` → `yourproject_app`)
* Rename the network under `networks:` (`stack_net` → `yourproject_net`) and its references in each service

### 4. Build and Start

```bash
docker compose build --no-cache
docker compose up -d
```

`--no-cache` matters on first build so PHP extensions (intl, opcache, gd with jpeg/freetype support) install cleanly.

---

## ➕ Adding a New Project

### 1. Drop the project into `src/`

```
src/yourproject.local/
```

### 2. Nginx Configuration

Duplicate the template and rename it (drop the `.template` extension so nginx actually loads it):

```bash
cp docker/nginx/conf.d/example.conf.template docker/nginx/conf.d/yourproject.local.conf
```

Update `server_name` and `root` inside the new file to match your project's folder and public path.

### 3. Hosts File (Linux)

Map the local domain to your loopback address:

```bash
sudo nano /etc/hosts
```

Add a line at the bottom (IP first, then hostname):

```
127.0.0.1   yourproject.local
```

No restart needed — takes effect on save.

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
* **From the host machine** (a desktop MySQL client, DBeaver, etc.): `127.0.0.1`, port `3307`
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

# Host-level env (UID/GID are machine-specific)
.env
```

---

## 🔧 Notes

* PHP extensions installed: `pdo_mysql`, `mbstring`, `exif`, `pcntl`, `bcmath`, `gd` (with jpeg/freetype support), `zip`, `intl`, `opcache`.
* `opcache.validate_timestamps=1` is set for local dev so file changes show up without a container restart. For a production/VPS build, switch this to `0` for full opcache performance.
* `client_max_body_size 64M;` is set in the nginx template to match PHP's `upload_max_filesize`/`post_max_size` — without it, nginx rejects large uploads before they even reach PHP, regardless of the PHP-side limits.
* `entrypoint.sh` only `chown`/`chmod`s each project's `storage/` and `bootstrap/cache/` on container start, not the whole `src/` tree — keeps startup fast as you add more projects.
