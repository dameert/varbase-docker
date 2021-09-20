# varbase-docker ![Continuous Docker Image Build](https://github.com/ems-project/varbase-docker/workflows/Continuous%20Docker%20Image%20Build/badge.svg)

## Prerequisite
Before launching the bats commands you must defined the following environment variables:
```dotenv
VARBASE_DOCKER_IMAGE_NAME=varbase-0-0-2  #locally build docker image name or:
BATS_VARBASE_VERSION=9.0.1 #the varbase version you want to test, considering this image has been published on dockerhub
BATS_GITHUB_OAUTH=PrivateGithubOauthToken #your github token will be used when building the image during composer install
```
You must also install `bats`.

## Commands
- `bats test/build.bats` : builds the docker image
- `bats test/tests.bats` : tests the image

Drupal Varbase in Docker containers

## Environment variables
### PUID
Define the user identifier. Default value `1001`.



## Magick command to remove all
```docker stop $(docker ps -a -q) && docker rm $(docker ps -a -q)```

Caution, it removes every running pod.

If you want to also remove all persisted data in your docker environment:
`docker volume rm $(docker volume ls -q)`

## Development
Compress a dump:
`cd test/dumps/ && tar -zcvf example.tar.gz example.dump && cd -`
