FROM ghcr.io/jarvusinnovations/habitat-compose:latest as runtime-deps

# configure environment
ARG HAB_LICENSE=no-accept
ENV HAB_LICENSE=$HAB_LICENSE
ENV STUDIO_TYPE=Dockerfile
ENV HAB_ORIGIN=emergence-site

# configure persistent volumes
RUN hab pkg exec core/coreutils mkdir -p '/hab/svc/mysql/data' '/hab/svc/site/data' '/hab/svc/nginx/files' \
    && hab pkg exec core/coreutils chown hab:hab -R '/hab/svc/mysql/data' '/hab/svc/site/data' '/hab/svc/nginx/files'

# configure entrypoint
VOLUME ["/hab/svc/mysql/data", "/hab/svc/site/data", "/hab/svc/nginx/files"]
ENTRYPOINT ["hab", "sup", "run"]
CMD ["emergence-site/site-composite"]

# generate origin key
RUN hab origin key generate

# install dependencies
RUN hab pkg install \
        core/bash \
        core/mysql \
        emergence/nginx \
    && hab pkg exec core/coreutils rm -rf /hab/cache/artifacts/ /hab/cache/src/

# install runtime
ARG RUNTIME_PKG=emergence/php-runtime
RUN hab pkg install ${RUNTIME_PKG} \
    && hab pkg exec core/coreutils rm -rf /hab/cache/artifacts/ /hab/cache/src/


### Additional target with build dependencies
FROM runtime-deps as build-deps

# install buildtime dependencies
RUN hab pkg install \
        core/hab-plan-build \
        jarvus/hologit \
        jarvus/toml-merge \
        emergence/scaffolding-site \
        emergence/scaffolding-composite \
    && hab pkg exec core/coreutils rm -rf /hab/cache/artifacts/ /hab/cache/src/

# copy Habitat template in
COPY ./habitat-template /src/habitat
