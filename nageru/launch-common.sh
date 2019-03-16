if (( $# > 1 )); then
    RECORDING_DIR="$(readlink -f "$2")"
else
    RECORDING_DIR="$HERE/recordings"
    mkdir -p "$RECORDING_DIR"
fi

COMMON_ARGS="\
  -I. -tbreizhcamp.lua
  --midi-mapping="$HERE/akai.midimapping" \
  --disable-alsa-output \
  --disable-gain-staging-auto \
  --disable-makeup-gain-auto \
  --mjpeg-export-cards="" \
  --recording-dir="$RECORDING_DIR" \
  --fullscreen \
"
