#!/bin/bash

TARGET_DIR=$(readlink -f "$1")

if [[ ! -d $TARGET_DIR ]]; then
  echo "First arg must be set to target directory"
  exit 1
fi

for i in "$@"; do
  filename=$(basename "$i")
  target_file="$TARGET_DIR/$(echo "${filename%%.nut}"|sed 's/[:+]//g').mkv"
  
  if [[ ! -r $target_file ]]; then
    cat "$i" | ffmpeg -i - -acodec copy -vcodec copy "$target_file"
  fi
done

