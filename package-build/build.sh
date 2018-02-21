#!/bin/bash

export PACKAGE_NAME="$1"
docker-compose -p package-builder -f docker-compose.yaml up --build
