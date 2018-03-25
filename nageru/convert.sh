#!/bin/bash

for i in $HOME/Vidéos/*nut; do
  cat $i | ffmpeg -i - -vcodec copy $(echo ${i%%.nut}|sed 's/[:+]//g').mp4
  cat $i | ffmpeg -i - -acodec copy $(echo ${i%%.nut}|sed 's/[:+]//g').wav
done

mkdir -p $HOME/Vidéos/old
mv $HOME/Vidéos/*nut $HOME/Vidéos/old
