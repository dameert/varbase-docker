#!/usr/bin/env bats
load "helpers/tests"
load "helpers/docker"

load "lib/batslib"
load "lib/output"

export BATS_ROOT_DB_USER="${BATS_ROOT_DB_USER:-root}"
export BATS_ROOT_DB_PASSWORD="${BATS_ROOT_DB_PASSWORD:-password}"
export BATS_ROOT_DB_NAME="${BATS_ROOT_DB_PASSWORD:-root}"

export BATS_DB_DRIVER="${BATS_DB_DRIVER:-mysql}"
export BATS_DB_HOST="${BATS_DB_HOST:-mysql}"
export BATS_DB_PORT="${BATS_DB_PORT:-3306}"
export BATS_DB_USER="${BATS_DB_USER:-example_adm}"
export BATS_DB_PASSWORD="${BATS_DB_PASSWORD:-example}"
export BATS_DB_NAME="${BATS_DB_NAME:-example}"
export BATS_SERVER_NAME="${BATS_SERVER_NAME:-localhost}"
export BATS_HASH_SALT="${BATS_HASH_SALT:-thisisadummysaltthatcannotbetrusted}"
export BATS_TRUSTED_HOST_PATTERNS="${BATS_TRUSTED_HOST_PATTERNS:-[\"localhost\"]}"

export BATS_PHP_FPM_MAX_CHILDREN="${BATS_PHP_FPM_MAX_CHILDREN:-4}"
export BATS_PHP_FPM_REQUEST_MAX_MEMORY_IN_MEGABYTES="${BATS_PHP_FPM_REQUEST_MAX_MEMORY_IN_MEGABYTES:-128}"
export BATS_CONTAINER_HEAP_PERCENT="${BATS_CONTAINER_HEAP_PERCENT:-0.80}"

export BATS_STORAGE_SERVICE_NAME="mysql"

export BATS_VARBASE_DOCKER_IMAGE_NAME="${VARBASE_DOCKER_IMAGE_NAME:-docker.io/elasticms/varbase:rc}"
export BATS_VARBASE_VERSION="${VERSION_ARG:-9.0.1}"
export BATS_RELEASE_NUMBER=${RELEASE_NUMBER:-snapshot}
export BATS_BUILD_DATE=${BUILD_DATE:-snapshot}
export BATS_VCS_REF=${VCS_REF:-snapshot}
export BATS_GITHUB_OAUTH=${GITHUB_OAUTH:-none}

@test "[$TEST_FILE] Starting Varbase Storage Services (MySql)" {
  command docker-compose -f docker-compose.yml up -d mysql
  docker_wait_for_log mysql 240 "Starting MySQL"
}

@test "[$TEST_FILE] Starting Varbase services (webserver, php-fpm) configured for Volume mount" {
  command docker-compose -f docker-compose.yml up -d varbase
  docker_wait_for_log varbase 15 "Install \[ default \] CMS Domain from Environment variables successfully ..."
  docker_wait_for_log varbase 15 "NOTICE: ready to handle connections"
  docker_wait_for_log varbase 15 "AH00292: Apache/.* \(Unix\) OpenSSL/.* configured -- resuming normal operations"

}

@test "[$TEST_FILE] Varbase default drush script in running container for default domain" {
    run docker exec varbase sh -c "/opt/bin/default drupal:directory"
    assert_output -l 0 "/opt/src/docroot"
}


@test "[$TEST_FILE] Check for Varbase Default Index page response code 200" {
  retry 12 5 curl_container varbase :9000/index.php -H 'Host: default.localhost' -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Check for Varbase status page response code 200 for default domains" {
    retry 12 5 curl_container varbase :9000/core/install.php -H "'Host: ${SERVER_NAME}'" -s -w %{http_code} -o /dev/null
    assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Check for Monitoring /real-time-status page response code 200" {
  retry 12 5 curl_container varbase :9000/real-time-status -H 'Host: default.localhost' -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Check for Monitoring /status page response code 200" {
  retry 12 5 curl_container varbase :9000/status -H 'Host: default.localhost' -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Check for Monitoring /server-status page response code 200" {
  retry 12 5 curl_container varbase :9000/server-status -H 'Host: default.localhost' -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Stop all and delete test containers" {
  command docker-compose -f docker-compose.yml stop
  command docker-compose -f docker-compose.yml rm -v -f
}
