#!/bin/bash

for i in /home/capture2/Vidéos/*nut; do
  cat $i | ffmpeg -i - -vcodec copy $(echo ${i%%.nut}|sed 's/[:+]//g').mp4
done

rm /home/capture2/Vidéos/*nut

