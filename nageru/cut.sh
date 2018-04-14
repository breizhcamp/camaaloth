#!/bin/bash

file="$1"

if [[ ! -r $file ]];then
    echo "First arg is the file to cut"
    exit 1
fi

ffmpeg -i "$file" -ss "$2" -ab 192k -af afade=t=in:st=00:d=3 -acodec aac -vcodec copy "$(dirname "$file")/video.ts"

