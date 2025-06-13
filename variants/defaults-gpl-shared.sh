#!/bin/bash
source "$(dirname "$BASH_SOURCE")"/defaults-gpl.sh
FF_CONFIGURE+="--disable-everything --enable-shared --disable-static --enable-libx264 --enable-encoder=h264_qsv --enable-encoder=h264_amf"
