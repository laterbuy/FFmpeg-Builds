#!/bin/bash
source "$(dirname "$BASH_SOURCE")"/defaults-gpl.sh
FF_CONFIGURE+=" --disable-everything --enable-shared --disable-static --enable-encoder=h264_* --enable-libx264 --enable-encoder=libx264 --enable-swscale --enable-pthreads --enable-libvpl --enable-amf"
