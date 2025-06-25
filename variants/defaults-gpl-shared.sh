#!/bin/bash
source "$(dirname "$BASH_SOURCE")"/defaults-gpl.sh
FF_CONFIGURE+=" --disable-everything --disable-shared --enable-static --enable-encoder=h264_* --enable-libx264 --enable-encoder=libx264 --enable-swscale --enable-pthreads --enable-libvpl --enable-amf --enable-encoder=aac --pkg-config-flags="--static""
