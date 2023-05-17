#!/usr/bin/env sh

SELF_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"

cp -v "${SELF_DIR}/notify.lua" ~/.config/mpv/scripts/
