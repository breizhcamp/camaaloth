#!/bin/bash

HERE=$(dirname "$(readlink -f "$0")")

cd "$HERE/themes"
nageru -I. -tbreizhcamp.lua \
 -c 4 \
 --map-signal=1,0 --map-signal=0,1 \
 --alsa-delay=40 --disable-alsa-output --audio-queue-length-ms=150 \
 --input-mapping="$HERE/focusrite-18i8.mapping" --disable-gain-staging-auto \
 --recording-dir="$HOME/Vidéos/" \
 --full-screen \
 "$@"

