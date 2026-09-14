# Dockerized Municipio Build

This Dockerfile builds Municipio from a Git repository during the image build. The repository and optional branch or tag can be configured with Docker build arguments.

## Build Arguments

| Argument | Default | Description |
| --- | --- | --- |
| `MUNICIPIO_DEPLOYMENT_REPOSITORY` | `https://github.com/municipio-se/municipio-deployment.git` | Git repository to clone before running Composer and the Municipio build script. |
| `MUNICIPIO_DEPLOYMENT_REF` | empty | Optional branch or tag to clone. When empty, Git clones the repository default branch. |

## Examples

Build with the default repository and its default branch:

```sh
docker build -t municipio .
```

Build from a specific branch:

```sh
docker build \
  --build-arg MUNICIPIO_DEPLOYMENT_REF=master \
  -t municipio .
```

Build from a specific tag:

```sh
docker build \
  --build-arg MUNICIPIO_DEPLOYMENT_REF=v1.0.0 \
  -t municipio .
```

Build from another repository:

```sh
docker build \
  --build-arg MUNICIPIO_DEPLOYMENT_REPOSITORY=https://github.com/example/municipio-deployment.git \
  -t municipio .
```

Build from another repository and a specific branch or tag:

```sh
docker build \
  --build-arg MUNICIPIO_DEPLOYMENT_REPOSITORY=https://github.com/example/municipio-deployment.git \
  --build-arg MUNICIPIO_DEPLOYMENT_REF=my-branch-or-tag \
  -t municipio .
```

The selected repository must contain the expected Municipio deployment structure, including `composer.json` and `build.php`, because the Dockerfile runs `composer install` and `php ./build.php` after cloning.