# htmly-app

[![production workflow](https://github.com/glauciolabs/htmly-app/actions/workflows/production.yml/badge.svg)](https://github.com/glauciolabs/htmly-app/actions/workflows/production.yml)

Repository for the `HTMLy` application with manifests for development and production, plus the container used for local builds and runtime.

## Structure

- `container/htmly`: Docker image, `docker-entrypoint.sh`, and `compose.yaml`
- `app/develop`: Kubernetes manifests for the development environment
- `app/production`: Kubernetes manifests for the production environment
- `info.yaml`: general app metadata

## Local Run

The project includes a `compose.yaml` file in `container/htmly` to run the container locally.

```bash
cd container/htmly
docker compose up --build
```

## Deploy

The Kubernetes manifests are split by environment and can be applied with `kustomize`.

```bash
kubectl apply -k app/develop
kubectl apply -k app/production
```

## Secrets

The `secrets.yaml` files are ignored by git, so each environment needs its secrets provided locally before deployment.
