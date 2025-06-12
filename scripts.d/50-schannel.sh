#!/bin/bash

SCRIPT_SKIP="1"

ffbuild_enabled() {
    return -1
}

ffbuild_dockerdl() {
    true
}

ffbuild_dockerstage() {
    return 0
}

ffbuild_dockerbuild() {
    return 0
}

ffbuild_configure() {
    echo --enable-schannel
}

ffbuild_unconfigure() {
    echo --disable-schannel
}
