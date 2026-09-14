# syntax=docker/dockerfile:1.7
FROM webbutvecklinghelsingborg/gitops:openlitespeed-0.0.3

# WP-CLI is baked in here rather than fetched by prepare_wordpress.sh at boot.
# The entrypoint used to mv it into /usr/bin, which fails the moment the
# container runs as anything but root -- and takes the whole entrypoint with it,
# because entrypoint-wrapper.sh runs under `set -e`. Installing at build time
# also drops a network fetch from every pod start.
#
# USER root is believed to be a no-op -- the base image's entrypoint already
# writes to /usr/bin -- but it is the last USER in this file, so it does decide
# the runtime user. Confirm with:
#   docker image inspect webbutvecklinghelsingborg/gitops:openlitespeed-0.0.3 \
#     --format 'User={{.Config.User}}'
USER root

# install git
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

# PHP ini overrides for this dev/debug environment (see php-overrides.ini),
# copied into the mods-available scan-dir so they load after and override the
# base image's lsphp config. Filename is prefixed "zz-" so it sorts/loads last.
COPY --chown=1000:1000 --chmod=644 php-overrides.ini \
    /usr/local/lsws/lsphp84/etc/php/8.4/mods-available/zz-overrides.ini

# Install WP-CLI
RUN curl -fsSL -o /usr/local/bin/wp \
    https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod 755 /usr/local/bin/wp \
    && wp --version --allow-root

# install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# install node 24.*
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# Set the working directory for the application to the location where the Municipio deployment will be cloned and served
WORKDIR /var/www/vhosts/localhost/html

# Clone the Municipio deployment repository
ARG MUNICIPIO_DEPLOYMENT_REPOSITORY=https://github.com/municipio-se/municipio-deployment.git
ARG MUNICIPIO_DEPLOYMENT_REF=main
RUN if [ -n "$MUNICIPIO_DEPLOYMENT_REF" ]; then \
    git clone --branch "$MUNICIPIO_DEPLOYMENT_REF" --single-branch "$MUNICIPIO_DEPLOYMENT_REPOSITORY" .; \
    else \
    git clone "$MUNICIPIO_DEPLOYMENT_REPOSITORY" .; \
    fi

ARG ACF_PRO_KEY

# Build the project with Composer and the Municipio build script
RUN export COMPOSER_AUTH='{"http-basic": {"connect.advancedcustomfields.com": {"username": "'"$ACF_PRO_KEY"'", "password": "http://localhost"}}}' && \
    composer install --prefer-dist --no-progress --no-suggest --optimize-autoloader --classmap-authoritative && \
    php ./build.php --cleanup --no-composer-in-child-packages --install-npm && \
    chown -R 1000:1000 . && \
    chmod -R 755 .

# Copy htaccess files
COPY --chown=1000:1000 --chmod=755 htaccess ./htaccess

# Copy configuration files
COPY --chown=1000:1000 --chmod=755 config ./config

# Copy setup scripts
COPY --chown=1000:1000 --chmod=755 setup ./setup

# Expose the web server ports
EXPOSE 80 7080

# Define a health check for the web server
HEALTHCHECK CMD test "$(curl -s -o /dev/null -w '%{http_code}' http://localhost/)" = "200"

ENTRYPOINT ["./setup/setup.sh"]
