# varbase-docker ![Continuous Docker Image Build](https://github.com/ems-project/varbase-docker/workflows/Continuous%20Docker%20Image%20Build/badge.svg)

## Drupal Varbase in Docker containers

## Environment variables

### PUID
Define the user identifier. Default value `1001`.

### VARBASE_EXEC_{filename}
Execute the {filename}.sh file that is injected into the folder `/opt/bin/extra` inside the docker container.

For example set the following variable to launch the drush updates when installing new versions (be aware that you should not run this on multiple replicas connecting to the same DB):
```dotenv
VARBASE_EXEC_UPDATE='runs /opt/bin/extra/update.sh on container startup'
```


## Automated testing

### Prerequisite
Before launching the bats commands you must defined the following environment variables:
```dotenv
VARBASE_DOCKER_IMAGE_NAME=varbase-0-0-2  #locally build docker image name or:
BATS_VARBASE_VERSION=9.0.1 #the varbase version you want to test, considering this image has been published on dockerhub
BATS_GITHUB_OAUTH=PrivateGithubOauthToken #your github token will be used when building the image during composer install
```
You must also install `bats`.

### Commands
- `bats test/build.bats` : builds the docker image
- `bats test/tests.bats` : tests the image
