#!/bin/bash

HERE=$(dirname "$(readlink -f "$0")")
systemd-run  --user --unit camaaloth-launcher "${HERE}/launcher.sh"
journalctl --user --unit camaaloth-launcher -f