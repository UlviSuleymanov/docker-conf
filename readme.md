# Standart Docker Configuration for PHP, Nginx, MariaDB. fine tuned for Laravel 13 applications. (windows)

# you need to create src folder on root and conf folder on docker/nginx based on project name change docker-compose.yml
# for example name root is stack rename containers by this folder name ie container_name: stack_app (networks too) default is stack

# each new project on src folder create new conf file on docker/nginx/conf folder (based on example.conf) 
# and you need to create new alias for windows hosts file.(windows/system32/drivers/hosts) 127.0.0.1    example.local