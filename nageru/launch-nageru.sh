#!/bin/bash

HERE=$(dirname "$(readlink -f "$0")")

declare -A per_host_args
per_host_args[capture-1]="-c 2"
per_host_args[capture-2]="-c 4 --output-card 3 --flat-audio"
per_host_args[capture-3]="-c 4 --output-card 3"

if (( $# > 1 )); then
    RECORDING_DIR="$(readlink -f "$2")"
else
    RECORDING_DIR="$HERE/recordings"
    mkdir -p "$RECORDING_DIR"
fi

camaaloth_id="${HOSTNAME}"

cd "${HERE}/themes" || exit
exec nageru \
  -I. -tbreizhcamp.lua \
  --midi-mapping="${HERE}/mappings/akai.midimapping" \
  --input-mapping="${HERE}/mappings/${camaaloth_id}.mapping" \
  --disable-alsa-output \
  --disable-gain-staging-auto \
  --disable-makeup-gain-auto \
  --mjpeg-export-cards="" \
  --recording-dir="${RECORDING_DIR}" \
  --fullscreen \
  ${per_host_args[$camaaloth_id]}
