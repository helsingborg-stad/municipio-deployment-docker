# Municipio Docker image

This repository builds a ready-to-run [Municipio](https://github.com/municipio-se/municipio-deployment) WordPress image. The image contains OpenLiteSpeed, PHP, WordPress, WP-CLI, Composer, Node.js, and a selected Municipio deployment.

On its first start, the container connects to the database and installs WordPress automatically. Later starts reuse the existing database.

## Before you start

You need:

- Docker with Docker Compose
- An ACF Pro license key used to download ACF Pro while building the image
- A Municipio deployment repository and branch or tag (the defaults use the public Municipio deployment repository and its `main` branch)

Set the ACF Pro key in your shell so it does not need to be written into the Compose file:

```sh
export ACF_PRO_KEY="your-license-key"
```

## Quick start with Docker Compose

Create a `docker-compose.yml` with the following content. This is a small, single-site setup intended for local use.

```yaml
services:
  municipio:
    image: municipio:local
    build:
      context: .
      args:
        ACF_PRO_KEY: ${ACF_PRO_KEY:?Set ACF_PRO_KEY before building}
        MUNICIPIO_DEPLOYMENT_REPOSITORY: https://github.com/municipio-se/municipio-deployment.git
        MUNICIPIO_DEPLOYMENT_REF: main
    environment:
      WP_CONF_DB_NAME: municipio
      WP_CONF_DB_USER: municipio
      WP_CONF_DB_PASSWORD: municipio
      WP_CONF_DB_HOST: database
      WP_CONF_DB_TABLE_PREFIX: mun_
      WP_CONF_WP_HOME: http://localhost:9090
      WP_CONF_WP_SITEURL: http://localhost:9090/wp
      WP_CONF_DOMAIN_CURRENT_SITE: localhost:9090
      WP_CONF_WP_SITE_TITLE: Municipio
      WP_CONF_WP_ADMIN_USER: admin
      WP_CONF_WP_ADMIN_PASSWORD: change-me
      WP_CONF_WP_ADMIN_EMAIL: admin@example.com
      WP_CONF_WP_REDIS_DISABLED: true
    depends_on:
      database:
        condition: service_healthy
    ports:
      - "9090:80"
    volumes:
      - uploads-data:/var/www/vhosts/localhost/html/wp-content/uploads

  database:
    image: mariadb:11
    environment:
      MARIADB_DATABASE: municipio
      MARIADB_USER: municipio
      MARIADB_PASSWORD: municipio
      MARIADB_ROOT_PASSWORD: change-root-password
    healthcheck:
      test: ["CMD", "healthcheck.sh", "--connect", "--innodb_initialized"]
      interval: 5s
      timeout: 5s
      retries: 10
    volumes:
      - database-data:/var/lib/mysql

volumes:
  database-data:
  uploads-data:
```

The `build.context` must point to this repository because the image is built from its `Dockerfile`, configuration, and setup scripts.

Start the site:

```sh
docker compose up --build -d
```

The first build can take a few minutes. When the containers are ready, open:

- Site: <http://localhost:9090>
- WordPress administration: <http://localhost:9090/wp-admin>

Sign in with the admin username and password from the Compose file. Change the example passwords before sharing the environment with anyone else.

## Building the image directly

You can also build the image without Compose:

```sh
docker build \
  --build-arg ACF_PRO_KEY="$ACF_PRO_KEY" \
  --build-arg MUNICIPIO_DEPLOYMENT_REF=main \
  -t municipio:local .
```

The available build arguments are:

| Argument | Default | Purpose |
| --- | --- | --- |
| `ACF_PRO_KEY` | None | ACF Pro key used during dependency installation. |
| `MUNICIPIO_DEPLOYMENT_REPOSITORY` | Municipio's public deployment repository | Repository containing `composer.json` and `build.php`. |
| `MUNICIPIO_DEPLOYMENT_REF` | `main` | Branch or tag to include in the image. |

The deployment source is copied into the image when it is built. Rebuild the image when you want to use a different version or include new source changes.

## Common settings

Runtime settings use the `WP_CONF_` prefix. The most useful ones are:

| Setting | Purpose |
| --- | --- |
| `WP_CONF_DB_NAME` | Database name. |
| `WP_CONF_DB_USER` | Database user. |
| `WP_CONF_DB_PASSWORD` | Database password. |
| `WP_CONF_DB_HOST` | Database service name or host. |
| `WP_CONF_WP_HOME` | Public address of the site. |
| `WP_CONF_WP_SITEURL` | Address of WordPress core, normally the site address followed by `/wp`. |
| `WP_CONF_WP_ADMIN_USER` | Admin username created on the first start. |
| `WP_CONF_WP_ADMIN_PASSWORD` | Admin password created on the first start. |
| `WP_CONF_WP_ADMIN_EMAIL` | Admin email created on the first start. |
| `WP_CONF_WP_DEBUG` | Set to `true` to enable WordPress debugging. |
| `WP_CONF_WP_REDIS_DISABLED` | Set to `true` when no Redis or Valkey service is used. |

The database and admin values are only used to perform the initial installation. If a database volume already contains WordPress, changing the initial admin values will not update the existing account.

Any additional WordPress constant can be defined with `WP_CONF_EXTRA_`. For example, `WP_CONF_EXTRA_MY_SETTING: enabled` defines the `MY_SETTING` constant.

## Multisite

Multisite is optional. Add these settings to the `municipio` service to enable a subdomain network:

```yaml
environment:
  WP_CONF_WP_ALLOW_MULTISITE: true
  WP_CONF_SUBDOMAIN_INSTALL: true
  WP_CONF_DOMAIN_CURRENT_SITE: localhost:9090
```

For a real domain, make sure its DNS and local development setup route subdomains to the Docker host. Subdomain multisite on `localhost` may behave differently between browsers and operating systems.

## Useful commands

Follow startup logs:

```sh
docker compose logs -f municipio
```

Run WP-CLI:

```sh
docker compose exec municipio wp option get siteurl --allow-root
```

Stop the containers while keeping the database and uploaded files:

```sh
docker compose down
```

Remove the containers, database, and uploaded files, allowing a completely fresh installation next time:

```sh
docker compose down --volumes
```

## Notes for deployed environments

The example is deliberately simple and uses local development credentials. For a shared or public environment:

- Use strong, unique passwords and provide secrets through your deployment platform.
- Put the site behind HTTPS and set `WP_CONF_WP_HOME` and `WP_CONF_WP_SITEURL` to the public HTTPS addresses.
- Pin the MariaDB image and Municipio deployment to versions that you have tested.
- Back up the database and uploads volumes.
- Do not publish the OpenLiteSpeed administration port unless it is specifically needed and protected.
