FROM docker.io/elasticms/base-php-dev:7.4 as builder

ARG VERSION_ARG=""
ARG RELEASE_ARG=""
ARG BUILD_DATE_ARG=""
ARG GITHUB_OAUTH_ARG=""

ENV VARBASE_VERSION=${VERSION_ARG:-9.0.1}

COPY bin/buildtime/ /opt/bin/

RUN echo "Download and configure Varbase ..." \
    && mkdir -p /opt/src \
    && COMPOSER_MEMORY_LIMIT=-1 composer -vvvv create-project Vardot/varbase-project:${VARBASE_VERSION} varbase --no-dev --no-interaction --working-dir /opt/src \
    && COMPOSER_MEMORY_LIMIT=-1 composer -vvvv config github-oauth.github.com ${GITHUB_OAUTH_ARG} --working-dir /opt/src/varbase \
    && COMPOSER_MEMORY_LIMIT=-1 composer -vvvv remove drupal/core-project-message --working-dir /opt/src/varbase \
    && COMPOSER_MEMORY_LIMIT=-1 composer -vvvv require drush/drush --working-dir /opt/src/varbase \
    && COMPOSER_MEMORY_LIMIT=-1 composer -vvvv config extra.patches-file 'patches/patches.json' --working-dir /opt/src/varbase \
    && COMPOSER_MEMORY_LIMIT=-1 composer -vvvv require drupal/core:9.2.3 drupal/pathologic:1.0.0-alpha2 --working-dir /opt/src/varbase \
    && COMPOSER_MEMORY_LIMIT=-1 composer -vvvv require drupal/core:9.2.3 drupal/pathologic:1.0.0-alpha2 --working-dir /opt/src/varbase \
    && source /opt/bin/configure.sh \
    && chmod a-w /opt/src/varbase/docroot/sites/default/settings.php

FROM docker.io/elasticms/base-apache-fpm:7.4
ARG VERSION_ARG=""
ARG RELEASE_ARG=""
ARG BUILD_DATE_ARG=""

LABEL varbase.build-date=$BUILD_DATE_ARG \
      varbase.name="Varbase - Drupal" \
      varbase.description="Drupal Varbase distribution." \
      varbase.url="https://www.drupal.org/project/varbase" \
      varbase.vcs-url="https://github.com/Vardot/varbase-project" \
      varbase.vendor="https://www.vardot.com/" \
      varbase.version="$VERSION_ARG" \
      varbase.release="$RELEASE_ARG" \
      varbase.schema-version="1.0" \
      varbase.docker-image="drupal-9"

USER root

COPY bin/runtime/ /opt/bin/
COPY etc/ /usr/local/etc/

COPY --from=builder /opt/src/varbase /opt/src

RUN echo "Setup permissions on filesystem for non-privileged user ..." \
    && mkdir -p /opt/src/docroot/sites/default/files \
    && chmod -Rf +x /opt/bin \
    && chown -Rf ${PUID:-1001}:0 /opt \
    && find /opt -type d -exec chmod ug+x {} \;

USER ${PUID:-1001}

HEALTHCHECK --start-period=10s --interval=1m --timeout=5s --retries=5 \
        CMD curl --fail --header "Host: default.localhost" http://localhost:9000/index.php || exit 1
