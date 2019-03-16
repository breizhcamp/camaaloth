#!/bin/bash

HERE=$(dirname "$(readlink -f "$0")")
source "$HERE/launch-common.sh"

cd "$HERE/themes"
nageru $COMMON_ARGS \
  -c 2 \
  --input-mapping="$HERE/camaaloth1.mapping" \
  "$@"
