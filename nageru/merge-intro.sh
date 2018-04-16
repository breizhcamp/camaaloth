#!/bin/bash

for i in "$@";  do
    pushd "$i"
    if [[ ! -r intro.ts ]]; then
    ffmpeg -y -i ../intro-empty.ts -loop 1 -t 6 -i intro.png \
        -filter_complex "[1:v]fade=t=in:st=0:d=1,fade=t=out:st=4:d=1[v0];[v0]scale=-2:720[v1];[0:v][v1]overlay" \
        -acodec copy -c:v libx264 -preset veryslow -crf 6 \
        intro.ts
    fi

    source="$(find . -type f -name 'record*.nut' | head -n 1)"
    if [[ -r start_time && -r $source ]]; then
    start_time="$(cat start_time)" # HH:MM:SS seek time notation in FFmpeg
    echo "$start_time" | grep -q "^[0-9][0-9]:[0-9][0-9]:[0-9][0-9]$"
    valid_ts=$?
    if [[ ! valid_ts ]]; then
        echo "Invalid timestamp in start_time file"
    fi 
    if [[ ! -r video.ts && valid_ts ]]; then
        seek_arg="00:00:00"
        seek_ts="00.000"
        start_time_in_sec="00"
        if [[ $start_time != "00:00:00" ]]; then
            # We look for the keyframe just before the start time to accurately cut the source file and use copy codec
            # It is not pretty but there's no really any other solution
            start_time_in_sec="$(echo "$start_time"| awk -F: '{ print ($1 * 3600) + ($2 * 60) + $3 }')"
            seek_ts=$(ffprobe -loglevel error -skip_frame nokey -select_streams v:0 -show_entries frame=pkt_pts_time -of csv=print_section=0 "$source" | \
            while read keyframe_ts; do
                keyframe_in_sec="${keyframe_ts%.*}"
                if [[ $start_time_in_sec -gt $keyframe_in_sec ]]; then
                    previous_ts="$keyframe_ts"
                else
                    echo $previous_ts
                    break # stop reading from the pipe to kill ffprobe
                fi
            done)
        fi
        seek_sec="${seek_ts%.*}"
        seek_arg="$(($seek_sec / 3600)):$(($seek_sec / 60)):$(($seek_sec % 60)).${seek_ts#*.}"
        echo $seek_arg
        ffmpeg -y -i "$source" -ss "$seek_arg" -ab 192k -af "afade=t=in:st=$start_time_in_sec:d=3" -acodec aac -vcodec copy video.ts
    fi
    fi

    # mkv has the lowest MUX overhead, so use that for the final round
    if [[ ! -r final.mkv && -r video.ts ]]; then
    ffmpeg -y -i "concat:intro.ts|video.ts" \
        -acodec copy -c:v copy \
        final.mkv
    fi
    popd
done
