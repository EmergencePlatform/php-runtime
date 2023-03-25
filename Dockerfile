FROM ghcr.io/emergenceplatform/php-runtime:build-deps as builder

# input SITE parameters
ENV SITE_TREE=working
ARG SITE_VERSION
ENV SITE_VERSION=${SITE_VERSION}

# build application
COPY . /src
RUN hab pkg exec core/hab-plan-build hab-plan-build /src
RUN hab pkg exec core/hab-plan-build hab-plan-build /src/habitat/composite


### Final stage with only runtime dependencies
FROM ghcr.io/emergenceplatform/php-runtime:runtime-deps as runtime

# install .hart artifact from builder stage
COPY --from=builder /hab/cache/artifacts/$HAB_ORIGIN-* /hab/cache/artifacts/
RUN hab pkg install /hab/cache/artifacts/$HAB_ORIGIN-* \
    && rm -rf /hab/cache/artifacts/ /hab/cache/src/
