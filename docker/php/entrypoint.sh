#!/bin/bash
set -e

if [ -d /var/www/html ]; then
    for project in /var/www/html/*/; do
        for dir in storage bootstrap/cache; do
            target="${project}${dir}"
            if [ -d "$target" ]; then
                chown -R www-data:www-data "$target"
                chmod -R 775 "$target"
            fi
        done
    done
fi

exec "$@"
