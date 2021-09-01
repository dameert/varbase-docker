FROM docker.io/elasticms/base-php-dev:7.4 as builder

ARG VERSION_ARG=""
ARG RELEASE_ARG=""
ARG BUILD_DATE_ARG=""

ENV VARBASE_VERSION=${VERSION_ARG:-9.0.1} \

RUN echo "Download and configure Varbase ..." \
    && mkdir -p /opt/src \
    && COMPOSER_MEMORY_LIMIT=-1 composer -vvvv create-project Vardot/varbase-project:${VARBASE_VERSION} varbase --no-dev --no-interaction --working-dir /opt/src \
    && COMPOSER_MEMORY_LIMIT=-1 composer -vvvv remove drupal/core-project-message --working-dir /opt/src/varbase \
    && COMPOSER_MEMORY_LIMIT=-1 composer -vvvv require drush/drush --working-dir /opt/src/varbase \
    && COMPOSER_MEMORY_LIMIT=-1 composer -vvvv config extra.patches --json '{"drupal/datetime": {"https://www.drupal.org/project/drupal/issues/2966735": "patches/2966735-13-validate-datetime-views-filter.patch"}}' \
    && COMPOSER_MEMORY_LIMIT=-1 composer -vvvv update drupal/datetime \
    && cat >> /opt/src/varbase/docroot/sites/default/settings.php << EOL
$settings['install_profile'] = 'varbase';
$settings['hash_salt'] = getenv('HASH_SALT');
$settings['trusted_host_patterns'] = getenv('TRUSTED_HOST_PATTERNS');

$databases['default']['default'] = [
  'database' => getenv('MYSQL_DATABASE'),
  'driver' => 'mysql',
  'host' => getenv('MYSQL_HOST'),
  'namespace' => 'Drupal\\Core\\Database\\Driver\\mysql',
  'password' => urlencode(getenv('MYSQL_PASSWORD')),
  'port' => getenv('MYSQL_PORT'),
  'prefix' => '',
  'username' => getenv('MYSQL_USER'),
];

$https = getenv('FORCE_HTTPS');
if (false !== $https) {
    $settings['https'] = TRUE;
    $_SERVER['HTTPS'] = 'on';
}

$syncDir = getenv('CONFIG_SYNC_DIRECTORY');
if (false !== $syncDir) {
 $config_directories['sync'] = getenv('CONFIG_SYNC_DIRECTORY');
}

EOL \
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

COPY bin/ /opt/bin/
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
