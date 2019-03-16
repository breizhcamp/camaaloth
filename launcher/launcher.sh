#!/bin/bash

HERE=$(dirname "$(readlink -f "$0")")

declare -A per_host_room
per_host_room[capture-1]="Amphi D"
per_host_room[capture-2]="Amphi C"
per_host_room[capture-3]="Amphi B"

camaaloth_id="${HOSTNAME}"

exec java \
  -Xmx512m \
  -jar "${HERE}/../../camaaloth-launcher/build/libs/camaaloth-launcher-0.0.1-SNAPSHOT.jar" \
  --spring.config.location="${HERE}/application.yaml" \
  --camaaloth.breizhcamp.room="${per_host_room[$camaaloth_id]}" \
  --spring.profiles.active=breizhcamp "$@"
