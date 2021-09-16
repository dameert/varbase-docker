#!/usr/bin/env bats
load "helpers/tests"
load "helpers/docker"

load "lib/batslib"
load "lib/output"

export BATS_VARBASE_VERSION=${VARBASE_VERSION:-9.0.1}
export BATS_RELEASE_NUMBER=${RELEASE_NUMBER:-snapshot}
export BATS_BUILD_DATE=${BUILD_DATE:-snapshot}
export BATS_VCS_REF=${VCS_REF:-snapshot}
export BATS_GITHUB_OAUTH={GITHUB_OAUTH:-noDefault}

export BATS_STORAGE_SERVICE_NAME="mysql"

export BATS_VARBASE_DOCKER_IMAGE_NAME="${VARBASE_DOCKER_IMAGE_NAME:-docker.io/elasticms/varbase:rc}"

docker-compose -f docker-compose.yml build --compress --pull varbase >&2

@test "[$TEST_FILE] Check Varbase Docker images build" {
  run docker inspect --type=image ${BATS_VARBASE_DOCKER_IMAGE_NAME}
  [ "$status" -eq 0 ]
}
