#!/bin/bash

HERE=$(dirname "$(readlink -f "$0")")
source "$HERE/launch-common.sh"

cd "$HERE/themes"
nageru $COMMON_ARGS \
  -c 4 \
  --output-card 3 \
  --input-mapping="$HERE/camaaloth3.mapping" \
  "$@"
