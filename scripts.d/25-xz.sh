#!/bin/bash

SCRIPT_REPO="https://github.com/tukaani-project/xz.git"
SCRIPT_COMMIT="dd4a1b259936880e04669b43e778828b60619860"

ffbuild_enabled() {
    return -1
}

ffbuild_dockerbuild() {
    ./autogen.sh --no-po4a --no-doxygen

    local myconf=(
        --prefix="$FFBUILD_PREFIX"
        --disable-symbol-versions
        --disable-shared
        --enable-static
        --with-pic
    )

    if [[ $TARGET == win* || $TARGET == linux* ]]; then
        myconf+=(
            --host="$FFBUILD_TOOLCHAIN"
        )
    else
        echo "Unknown target"
        return -1
    fi

    ./configure "${myconf[@]}"
    make -j$(nproc)
    make install
}

ffbuild_configure() {
    echo --enable-lzma
}

ffbuild_unconfigure() {
    echo --disable-lzma
}
