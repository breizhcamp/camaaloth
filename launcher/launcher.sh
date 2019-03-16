#!/bin/bash

java \
  -Xmx512m \
  -jar "$(dirname "$0")/../../camaaloth-launcher/build/libs/camaaloth-launcher-0.0.1-SNAPSHOT.jar" \
  --spring.config.location="$(dirname "$0")/application.yaml" \
  --spring.profiles.active=breizhcamp "$@"
