#!/bin/bash

HERE=$(dirname "$(readlink -f "$0")")

cd "$HERE/themes"
nageru -I. -tbreizhcamp.lua \
 -c 5 --output-card 4 \
 --map-signal=0,1 \
 --map-signal=1,2 \
 --map-signal=2,3 \
 --map-signal=3,0 \
 --alsa-delay=73 --disable-alsa-output --audio-queue-length-ms=150 \
 --input-mapping="$HERE/focusrite.mapping" \
 --disable-gain-staging-auto \
 --recording-dir="$HOME/Vidéos/" \
 --full-screen \
 "$@"
