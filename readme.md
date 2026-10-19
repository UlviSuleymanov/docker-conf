# Docker Stack for Laravel 13

A streamlined Docker configuration featuring **PHP 8.3**, **Nginx**, **MariaDB**, and **phpMyAdmin**, designed for running multiple Laravel 13 applications side by side.

---

## 🖥️ Choose Your Operating System

This repo has a dedicated branch for each OS. **Clone the branch that matches your machine** — each branch contains an OS-specific `docker-compose.yml`, `Dockerfile`, and setup guide.

| OS | Branch | Clone Command |
|---|---|---|
| 🐧 **Linux (Ubuntu/Debian)** | `master` | `git clone <repo-url> stack` |
| 🪟 **Windows** | `windows` | `git clone -b windows <repo-url> stack` |
| 🍎 **macOS** | `mac` | `git clone -b mac <repo-url> stack` |

> [!IMPORTANT]
> **Don't mix branches.** Each branch is tailored for its OS — the Dockerfile, docker-compose, and instructions differ. Pick the one that matches your system and follow the README on that branch.

---

## 📖 What's in Each Branch

### 🐧 Linux (`master`)

* Uses host **UID/GID mapping** so container-created files have correct ownership on the host filesystem.
* Requires a `.env` file in the stack root with your `UID` and `GID`.
* Instructions use `bash`, `sudo nano /etc/hosts`, etc.

### 🪟 Windows (`windows`)

* Designed for **Docker Desktop for Windows** with the **WSL 2 backend**.
* No UID/GID mapping needed — Docker Desktop handles file permissions through its VM layer.
* Includes `.gitattributes` to prevent line ending (`CRLF`) issues that break shell scripts inside containers.
* Instructions use **PowerShell** and **Command Prompt**, with Windows-specific hosts file editing and port conflict troubleshooting.

### 🍎 macOS (`mac`)

* Designed for **Docker Desktop for Mac** (supports both **Apple Silicon** and **Intel**).
* No UID/GID mapping needed — Docker Desktop handles file permissions through its VM layer.
* Includes **VirtioFS** recommendation for best performance.
* Instructions cover macOS DNS cache flushing and AirPlay Receiver port conflicts.

---

## 🚀 Quick Start

### 1. Install Docker

| OS | Install |
|---|---|
| Linux | [docs.docker.com/engine/install/ubuntu](https://docs.docker.com/engine/install/ubuntu/) |
| Windows | [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop/) (enable WSL 2 backend) |
| macOS | [Docker Desktop for Mac](https://www.docker.com/products/docker-desktop/) (pick Apple Silicon or Intel) |

### 2. Clone the Correct Branch

```bash
# Linux
git clone <repo-url> stack

# Windows
git clone -b windows <repo-url> stack

# macOS
git clone -b mac <repo-url> stack
```

### 3. Build and Run

```bash
cd stack
docker compose build --no-cache
docker compose up -d
```

### 4. Follow the Branch README

Each branch's `readme.md` has complete step-by-step instructions for:
* Adding new Laravel projects
* Configuring Nginx virtual hosts
* Editing the hosts file
* Setting up database connections
* Troubleshooting common issues

---

## 🧩 Stack Components

| Service | Image | Host Port | Purpose |
|---|---|---|---|
| **app** | `php:8.3-fpm` (custom) | — | PHP-FPM with Composer and Laravel extensions |
| **nginx** | `nginx:alpine` | `80` | Web server / reverse proxy |
| **db** | `mariadb:11` | `3307` | Database server |
| **phpmyadmin** | `phpmyadmin:latest` | `8080` | Web-based database management |

### PHP Extensions Included

`pdo_mysql`, `mbstring`, `exif`, `pcntl`, `bcmath`, `gd` (jpeg + freetype), `zip`, `intl`, `opcache`

---

## 🗄️ Database Access

| From | Host | Port |
|---|---|---|
| Inside containers (Laravel `.env`) | `db` | `3306` |
| Host machine (DBeaver, TablePlus, etc.) | `127.0.0.1` | `3307` |
| Browser (phpMyAdmin) | `http://localhost:8080` | — |

Default credentials: `root` / `root`

---

## 📄 Project Structure

```
stack/
├── docker/
│   ├── nginx/
│   │   ├── example.conf          # nginx vhost template
│   │   └── conf.d/               # active vhost configs (gitignored)
│   └── php/
│       ├── Dockerfile
│       └── entrypoint.sh
├── src/                           # your Laravel projects (gitignored)
│   └── .gitkeep
├── docker-compose.yml
└── readme.md
```

---

## ❓ FAQ

**Q: Can I run multiple Laravel projects simultaneously?**
A: Yes — that's the whole point. Drop each project into `src/`, create an nginx config for it, add a hosts entry, and restart nginx.

**Q: Why port 3307 for MySQL?**
A: Port 3306 is the standard MySQL port and might conflict with a MySQL already running on your host. Mapping to 3307 avoids that while keeping 3306 inside the container (which is what Laravel connects to).

**Q: Do I need to install PHP or Composer on my machine?**
A: No. PHP, Composer, and all extensions run inside the `app` container. Use `docker compose exec app bash` to get a shell inside it.
