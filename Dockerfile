# syntax=docker/dockerfile:1.7
FROM webbutvecklinghelsingborg/gitops:openlitespeed-0.0.3 AS builder

# WP-CLI is baked in here rather than fetched by prepare_wordpress.sh at boot.
# The entrypoint used to mv it into /usr/bin, which fails the moment the
# container runs as anything but root -- and takes the whole entrypoint with it,
# because entrypoint-wrapper.sh runs under `set -e`. Installing at build time
# also drops a network fetch from every pod start.
#
# USER root is needed for the build dependencies and is also used by the
# runtime stage because the base image's entrypoint writes to /usr/bin. Confirm
# the base image's default with:
#   docker image inspect webbutvecklinghelsingborg/gitops:openlitespeed-0.0.3 \
#     --format 'User={{.Config.User}}'
USER root

# install git
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

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

# Build the project with Composer and the Municipio build script
RUN --mount=type=secret,id=acf_pro_key,required=true \
    ACF_PRO_KEY="$(cat /run/secrets/acf_pro_key)" && \
    export COMPOSER_AUTH='{"http-basic": {"connect.advancedcustomfields.com": {"username": "'"$ACF_PRO_KEY"'", "password": "http://localhost"}}}' && \
    composer install --prefer-dist --no-progress --no-suggest --optimize-autoloader --classmap-authoritative && \
    php ./build.php --cleanup --no-composer-in-child-packages --install-npm && \
    rm -rf .git && \
    chown -R 1000:1000 . && \
    chmod -R 755 .
# Start from a clean copy of the runtime image so build tools and package
# manager caches do not become part of the deployed image.
FROM webbutvecklinghelsingborg/gitops:openlitespeed-0.0.3 AS runtime

USER root

WORKDIR /var/www/vhosts/localhost/html

# WP-CLI is needed by the startup scripts, but Composer, Node.js, npm, and Git
# are build-only dependencies and stay in the builder stage.
COPY --from=builder /usr/local/bin/wp /usr/local/bin/wp
COPY --from=builder --chown=1000:1000 /var/www/vhosts/localhost/html/ ./

# Copy htaccess files
COPY --chown=1000:1000 --chmod=755 htaccess ./htaccess

# Copy configuration files
COPY --chown=1000:1000 --chmod=755 config ./config

# Copy setup scripts
COPY --chown=1000:1000 --chmod=755 setup ./setup

# Expose the web server ports
EXPOSE 80

# Define a health check for the web server
HEALTHCHECK CMD test "$(curl -s -o /dev/null -w '%{http_code}' http://localhost/)" = "200"

ENTRYPOINT ["./setup/setup.sh"]
