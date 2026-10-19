# Docker Stack for Laravel 13 (Windows)

A streamlined Docker configuration featuring **PHP 8.3**, **Nginx**, **MariaDB**, and **phpMyAdmin**, fine-tuned for running multiple Laravel 13 applications side by side on Windows.

---

## ⚙️ Prerequisites

1. **Docker Desktop for Windows** — download and install from [docker.com](https://www.docker.com/products/docker-desktop/).
2. During installation (or afterwards in Settings → General), make sure **"Use the WSL 2 based engine"** is checked — it's the default on modern Windows and gives much better file I/O performance than the legacy Hyper-V backend.
3. After installation, open a terminal and confirm Docker is running:

```powershell
docker --version
docker compose version
```

> [!NOTE]
> You do **not** need to install WSL or a Linux distro yourself — Docker Desktop handles its own lightweight WSL 2 VM internally. Just make sure the WSL 2 engine toggle is on.

---

## 🚀 Initial Setup

### 1. Clone This Repository

Open **PowerShell** or **Command Prompt** and clone the repo:

```powershell
git clone -b windows <repo-url> stack
cd stack
```

### 2. Project Structure

The stack expects this layout:

```
stack\
├── docker\
│   ├── nginx\
│   │   └── conf.d\          # per-project nginx vhosts + example.conf template
│   └── php\
│       ├── Dockerfile
│       └── entrypoint.sh
├── src\                      # your Laravel projects live here, one folder each
├── docker-compose.yml
└── .gitattributes            # keeps shell script line endings correct
```

Only `docker/nginx/example.conf` is committed — real per-project `.conf` files and everything under `src/` are project-specific and gitignored.

### 3. Build and Start

```powershell
docker compose build --no-cache
docker compose up -d
```

`--no-cache` matters on first build so PHP extensions install cleanly.

> [!IMPORTANT]
> If port **80** is already in use (common on Windows — IIS, Skype, or other services may claim it), either stop that service or change the nginx port mapping in `docker-compose.yml` from `"80:80"` to e.g. `"8000:80"`, and access your projects on `http://yourproject.local:8000` instead.

---

## ➕ Adding a New Project

### 1. Drop the project into `src\`

```
src\yourproject.local\
```

### 2. Nginx Configuration

Copy the example config and rename it:

**PowerShell:**
```powershell
Copy-Item docker\nginx\example.conf docker\nginx\conf.d\yourproject.local.conf
```

**Command Prompt:**
```cmd
copy docker\nginx\example.conf docker\nginx\conf.d\yourproject.local.conf
```

Open `docker\nginx\conf.d\yourproject.local.conf` in your editor and update `server_name` and `root` to match your project:

```nginx
server_name yourproject.local;
root /var/www/html/yourproject.local/public;
```

> [!NOTE]
> Paths inside the nginx config use **forward slashes** (`/var/www/html/...`) — these are container paths, not Windows paths.

### 3. Hosts File (Windows)

You need to map your local domain to `127.0.0.1`. The hosts file on Windows is at:

```
C:\Windows\System32\drivers\etc\hosts
```

**Option A — Notepad (as Administrator):**

1. Press `Win`, type **Notepad**, right-click → **Run as administrator**
2. File → Open → navigate to `C:\Windows\System32\drivers\etc\hosts` (change the filter from "Text Documents" to "All Files" to see it)
3. Add a line at the bottom:

```
127.0.0.1   yourproject.local
```

4. Save and close.

**Option B — PowerShell (as Administrator):**

```powershell
Add-Content C:\Windows\System32\drivers\etc\hosts "127.0.0.1   yourproject.local"
```

> [!IMPORTANT]
> The hosts file requires **Administrator** privileges to edit. Right-click your terminal → "Run as administrator" before using Option B.

### 4. Project `.env`

Inside `src\yourproject.local\.env`, point the database connection at the `db` **service name** — not `127.0.0.1` or `localhost`. Containers on the same Docker network don't share a loopback interface, so `127.0.0.1` from inside `app` only ever means the `app` container itself.

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

```powershell
docker compose restart nginx
docker compose exec app bash -c "cd /var/www/html/yourproject.local && php artisan config:clear"
```

Visit `http://yourproject.local`.

---

## 🗄️ Database Access

* **From inside containers** (Laravel, artisan): `DB_HOST=db`, port `3306`
* **From the host machine** (a desktop MySQL client, DBeaver, HeidiSQL, etc.): `127.0.0.1`, port `3307`
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

## ⚠️ Windows-Specific Troubleshooting

### Line Ending Issues

This repo includes a `.gitattributes` file that forces shell scripts (`.sh`) to use `LF` line endings. If you see errors like `/bin/bash^M: bad interpreter` or `entrypoint.sh: not found`, the line endings got converted to `CRLF`.

**Fix:**
```powershell
git config core.autocrlf input
git rm --cached -r .
git reset --hard
docker compose build --no-cache
```

### Slow File I/O / Performance

If your project feels noticeably slow (page loads taking seconds), Docker Desktop's WSL 2 file sharing can be slow for large `vendor/` or `node_modules/` directories. Tips:

1. Make sure you're using the **WSL 2 backend** (Docker Desktop → Settings → General).
2. Keep `vendor/` inside the container by running `composer install` inside the container:
   ```powershell
   docker compose exec app bash -c "cd /var/www/html/yourproject.local && composer install"
   ```
3. If performance is still an issue, consider storing your project files inside the WSL 2 filesystem instead of the Windows filesystem (access via `\\wsl$\` in Explorer).

### Port Conflicts

Windows commonly has services on port 80 (IIS, W3SVC) or port 8080. Check what's using a port:

```powershell
netstat -ano | findstr :80
```

Stop the conflicting service or change the port mapping in `docker-compose.yml`.

---

## 🔧 Notes

* PHP extensions installed: `pdo_mysql`, `mbstring`, `exif`, `pcntl`, `bcmath`, `gd` (with jpeg/freetype support), `zip`, `intl`, `opcache`.
* `opcache.validate_timestamps=1` is set for local dev so file changes show up without a container restart. For a production/VPS build, switch this to `0` for full opcache performance.
* `client_max_body_size 64M;` is set in the nginx template to match PHP's `upload_max_filesize`/`post_max_size` — without it, nginx rejects large uploads before they even reach PHP, regardless of the PHP-side limits.
* `entrypoint.sh` only `chown`/`chmod`s each project's `storage/` and `bootstrap/cache/` on container start, not the whole `src/` tree — keeps startup fast as you add more projects.
* No `.env` file is needed in the stack root on Windows — the UID/GID user mapping used on Linux is not required because Docker Desktop handles file permissions through its WSL 2 file sharing layer.
