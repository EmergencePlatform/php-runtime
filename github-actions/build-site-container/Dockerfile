ARG BASE_IMAGE=ghcr.io/emergenceplatform/php-runtime:site-base
FROM ${BASE_IMAGE}

ARG SITE_VERSION
ENV SITE_VERSION=${SITE_VERSION}

COPY . /tmp/site-overlay/

# install site code into the pre-existing package path (via stable symlink)
RUN rm -rf "${SITE_PKG_PATH}/site" \
    && mv /tmp/site-overlay "${SITE_PKG_PATH}/site" \
    && rm -f "${SITE_PKG_PATH}/site/Dockerfile" \
    && echo "Site code installed to: $(readlink -f ${SITE_PKG_PATH})/site/"
