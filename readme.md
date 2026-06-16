# Docker Stack for Laravel 13 (Windows)

A streamlined, standard Docker configuration featuring **PHP**, **Nginx**, and **MariaDB**, specifically fine-tuned for Laravel 13 applications running on Windows environments.

---

## 🚀 Initial Setup

Before spinning up your containers, you need to establish the foundational directory structure and configure your base project environment.

### 1. Create Required Directories
Ensure the following directories exist in your project root:
* `/src` — This is where your Laravel project files will live.
* `/docker/nginx/conf` — This is where your Nginx configuration files will be stored.

### 2. Configure Your Project Name
By default, the base project name is set to `stack`. If you want to customize this to match your root folder name, you must update the `docker-compose.yml` file:
* Rename the `container_name` directives to match your project (e.g., change `stack_app` to `yourproject_app`).
* Update the associated Docker network names to match this new naming convention.

---

## ➕ Adding a New Project

For every new Laravel project you place into the `/src` folder, follow these two steps to ensure local routing works correctly:

### 1. Nginx Configuration
Create a new configuration file for your project inside the `/docker/nginx/conf` directory.
* You can duplicate the provided `example.conf` to use as a starting template.
* Update the `server_name` and `root` directives inside the new file to point to your new project's public directory.

### 2. Windows Hosts File
Map your local development domain to your localhost IP so your browser can resolve the application URL.
* Open Notepad or your preferred text editor as an **Administrator**.
* Open the Windows hosts file located at: `C:\Windows\System32\drivers\etc\hosts`
* Add a new entry for your project at the bottom of the file. For example:
    ```text
    127.0.0.1    example.local
    ```