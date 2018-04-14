#!/bin/bash

for i in "$@";  do
    pushd "$i"
    if [[ ! -r intro.ts ]]; then
    ffmpeg -y -i ../intro-empty.ts -loop 1 -t 6 -i intro.png \
        -filter_complex "[1:v]fade=t=in:st=0:d=1,fade=t=out:st=4:d=1[v0];[v0]scale=-2:720[v1];[0:v][v1]overlay" \
        -acodec copy -c:v libx264 -preset veryslow -crf 10 \
        intro.ts
    fi
    if [[ ! -r final.mp4 && -r video.ts ]]; then
    ffmpeg -y -i "concat:intro.ts|video.ts" \
        -acodec copy -c:v copy \
        final.mp4
    fi
    popd
done
