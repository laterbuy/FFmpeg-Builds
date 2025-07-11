#!/bin/bash

SCRIPT_REPO="https://github.com/zeromq/libzmq.git"
SCRIPT_COMMIT="c2f7f8ae12720f48e97dc7d719da73cdab77e450"

ffbuild_enabled() {
    return -1
}

ffbuild_dockerbuild() {
    mkdir build && cd build

    local myconf=(
        -DCMAKE_TOOLCHAIN_FILE="$FFBUILD_CMAKE_TOOLCHAIN"
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_INSTALL_PREFIX="$FFBUILD_PREFIX"
        -DBUILD_SHARED=OFF
        -DBUILD_STATIC=ON
        -DBUILD_TESTS=OFF
        -DENABLE_INTRINSICS=ON
        -DENABLE_DRAFTS=OFF
        -DWITH_TLS=OFF
        -DWITH_DOCS=OFF
        -DENABLE_CPACK=OFF
        -DENABLE_NO_EXPORT=ON
    )

    if [[ $TARGET == win* ]]; then
        myconf+=( -DPOLLER="epoll" )
    fi

    cmake "${myconf[@]}" ..
    make -j$(nproc)
    make install

    {
        echo "Cflags.private: -DZMQ_NO_EXPORT -DZMQ_STATIC"
        [[ $TARGET != win* ]] || echo "Libs.private: -lws2_32 -liphlpapi"
    } >> "$FFBUILD_PREFIX"/lib/pkgconfig/libzmq.pc
}

ffbuild_configure() {
    echo --enable-libzmq
}

ffbuild_unconfigure() {
    echo --disable-libzmq
}
