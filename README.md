# php-runtime

Emergence PHP runtime for building and running emergence-based sites as Docker containers.

## Architecture

This system uses [Hologit](https://github.com/JarvusInnovations/hologit) to composite multi-layered emergence site repositories into a single application tree, which is then packaged into a Docker container with all needed runtime services (PHP-FPM, Nginx, MySQL) managed by [Habitat](https://www.habitat.sh/).

### Container images

- **`ghcr.io/emergenceplatform/php-runtime:site-base`** — A generic base image with all Habitat runtime infrastructure pre-installed but no site-specific code. Built once from a working donor site container and reused by all sites.
- **`ghcr.io/emergenceplatform/php-runtime:runtime-deps`** — Lower-level base with Habitat runtime packages (legacy, used by the original build pipeline).
- **`ghcr.io/emergenceplatform/php-runtime:build-deps`** — Extends runtime-deps with build tools (legacy, used by the original build pipeline).

## Building site containers

Site containers are built by the `build-site-container` GitHub Action, which:

1. Projects the site's `emergence-site` holobranch via Hologit (compositing all layers)
2. Overlays the projected tree onto the `site-base` image
3. Pushes the result to the site's container registry

### How it works

The `site-base` image contains a complete working Habitat service stack with an empty site code directory. A stable symlink at `/hab/pkgs/emergence-site/site/current` points to the actual package path. The site build simply copies the projected holo tree into `${SITE_PKG_PATH}/site/`.

### Usage from a site repository

```yaml
# .github/workflows/container-publish.yml
on:
  push:
    tags: ['v*']

jobs:
  container-publish:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    steps:
      - uses: EmergencePlatform/php-runtime@github-actions/build-site-container/v1
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
```

## Building/updating the site-base image

The `site-base` image is derived from an existing working emergence site container. It strips the site-specific application code while preserving all Habitat runtime infrastructure.

### Prerequisites

- Docker with access to `ghcr.io/emergenceplatform` (write) and the donor image (read)
- A working emergence site container to use as a donor (e.g. `ghcr.io/codeforphilly/codeforphilly.org:latest`)

### Steps

```bash
# 1. Build site-base from a working donor image
docker build --platform linux/amd64 \
  -f Dockerfile.site-base \
  --build-arg DONOR_IMAGE=ghcr.io/codeforphilly/codeforphilly.org:latest \
  -t ghcr.io/emergenceplatform/php-runtime:site-base .

# 2. Push to registry
docker push ghcr.io/emergenceplatform/php-runtime:site-base
```

Any working emergence site container can be used as the donor — the build detects the site package path automatically and creates a stable symlink for downstream use.

### When to rebuild

The `site-base` image only needs rebuilding if the underlying runtime infrastructure changes (PHP version, Nginx config, Habitat packages, etc.). Application code updates only require rebuilding the per-site container via the GitHub Action.

## Legacy build pipeline

The original pipeline used `hab-plan-build` inside the `build-deps` image to create Habitat `.hart` packages for each site. This required access to the Habitat Builder package repository, which is no longer freely available. The `Dockerfile` and `Dockerfile.site-base` approach bypasses Habitat Builder entirely by reusing pre-installed packages from an existing working container.
