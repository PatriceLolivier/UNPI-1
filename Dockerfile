# Dockerfile simple pour UNPI - PHP + nginx
FROM php:8.2-fpm-alpine

# Installation de nginx et supervisor seulement
RUN apk add --no-cache \
    nginx \
    supervisor

# Configuration du répertoire de travail
WORKDIR /app

# Copie des fichiers de l'application
COPY . /app/

# Configuration nginx personnalisée
COPY nginx.conf /etc/nginx/nginx.conf

# Configuration PHP-FPM simple pour nginx
RUN echo "listen = 127.0.0.1:9000" > /usr/local/etc/php-fpm.d/www.conf \
    && echo "pm = dynamic" >> /usr/local/etc/php-fpm.d/www.conf \
    && echo "pm.max_children = 5" >> /usr/local/etc/php-fpm.d/www.conf \
    && echo "pm.start_servers = 2" >> /usr/local/etc/php-fpm.d/www.conf \
    && echo "pm.min_spare_servers = 1" >> /usr/local/etc/php-fpm.d/www.conf \
    && echo "pm.max_spare_servers = 3" >> /usr/local/etc/php-fpm.d/www.conf

# Configuration Supervisor pour gérer nginx et PHP-FPM
RUN mkdir -p /var/log/supervisor
COPY <<EOF /etc/supervisor/conf.d/supervisord.conf
[supervisord]
nodaemon=true
logfile=/var/log/supervisor/supervisord.log
pidfile=/var/run/supervisord.pid

[program:php-fpm]
command=php-fpm -F
autostart=true
autorestart=true
stderr_logfile=/var/log/supervisor/php-fpm.err.log
stdout_logfile=/var/log/supervisor/php-fpm.out.log

[program:nginx]
command=nginx -g "daemon off;"
autostart=true
autorestart=true
stderr_logfile=/var/log/supervisor/nginx.err.log
stdout_logfile=/var/log/supervisor/nginx.out.log
EOF

# Permissions simples
RUN chown -R www-data:www-data /app \
    && chmod -R 755 /app

# Exposition du port
EXPOSE 80

# Commande de démarrage avec Supervisor
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
