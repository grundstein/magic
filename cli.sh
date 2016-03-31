#!/usr/bin/env bash
IMAGE_TAG="wiznwit:magic"

source ../../bin/tasks.sh

HOSTS_DIR=hosts

function loop-hosts() {
  echo "START: loop over hosts in dir $HOSTS_DIR with make task $2"
  task=$1

  for host_dir in $(ls $HOSTS_DIR); do \
    full_dir=$HOSTS_DIR/$host_dir
    if [ -d $full_dir ]; then
      echo "running 'make $task' in $full_dir"
      make -C $full_dir $task
      echo "SUCCESS: 'make $task' finished"
    else
      echo "FAIL: not a directory: $full_dir"
    fi
  done

  echo "FINISHED: loop over hosts"
}

function build() {
  echo "START: building $CONTAINER_NAME"

  cachebust=`git ls-remote https://github.com/magic/root.git | grep refs/heads/master | cut -f 1`
  echo "building with git hash $cachebust"

  docker build \
    --tag $IMAGE_TAG \
    --build-arg CACHEBUST=$cachebust \
    . # dot!

  build-hosts

  echo "FINISHED: building $CONTAINER_NAME"
}

function build-hosts() {
  echo "START: build hosts in $PWD/$HOSTS_DIR for $CONTAINER_NAME"

  loop-hosts build

  echo "FINISHED: build hosts in $CONTAINER_NAME"
}

function run() {
  echo "START: run hosts in $PWD/$HOSTS_DIR for $CONTAINER_NAME"

  loop-hosts run

  echo "FINISHED: run hosts for $CONTAINER_NAME"
}

function update() {
  echo "START: update $CONTAINER_NAME"
  git pull

  loop-hosts pull

  echo "FINISHED: update $CONTAINER_NAME"
}

function status() {
  git status

  loop-hosts status
}


function help() {
  echo "\
Usage
make magic-TASK
./cli.sh TASK

TASKS
  build       - build magic-root dependency containers

  build-hosts - build docker containers
  run         - run docker containers

  help        - this help text
"
}

if [ $1 ]
then
  function=$1
  shift
  $function $@
else
  help $@
fi
