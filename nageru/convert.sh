#!/bin/bash

for i in $HOME/Vidéos/*nut; do
  cat $i | ffmpeg -i - -acodec copy -vcodec copy $(echo ${i%%.nut}|sed 's/[:+]//g').mkv
done

mkdir -p $HOME/Vidéos/old
mv $HOME/Vidéos/*nut $HOME/Vidéos/old
