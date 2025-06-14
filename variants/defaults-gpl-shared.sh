#!/bin/bash
source "$(dirname "$BASH_SOURCE")"/defaults-gpl.sh
FF_CONFIGURE+=" --disable-everything --enable-shared --disable-static "
