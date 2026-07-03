#!/bin/bash
set -xe
shopt -s globstar
cd "$(dirname "$0")"
source util/vars.sh

source "variants/${TARGET}-${VARIANT}.sh"

for addin in ${ADDINS[*]}; do
    source "addins/${addin}.sh"
done

if docker info -f "{{println .SecurityOptions}}" | grep rootless >/dev/null 2>&1; then
    UIDARGS=()
else
    UIDARGS=( -u "$(id -u):$(id -g)" )
fi

rm -rf ffbuild
mkdir ffbuild

FFMPEG_REPO="${FFMPEG_REPO:-https://github.com/FFmpeg/FFmpeg.git}"
FFMPEG_REPO="${FFMPEG_REPO_OVERRIDE:-$FFMPEG_REPO}"
GIT_BRANCH="${GIT_BRANCH:-master}"
GIT_BRANCH="${GIT_BRANCH_OVERRIDE:-$GIT_BRANCH}"

BUILD_SCRIPT="$(mktemp)"
trap "rm -f -- '$BUILD_SCRIPT'" EXIT

cat <<EOF >"$BUILD_SCRIPT"
    set -xe
    cd /ffbuild
    rm -rf ffmpeg prefix

    git clone --filter=blob:none --branch='$GIT_BRANCH' '$FFMPEG_REPO' ffmpeg
    cd ffmpeg

    ./configure --prefix=/ffbuild/prefix --pkg-config-flags="--static" \\
        \$FFBUILD_TARGET_FLAGS \\
        --enable-gpl \\
        --enable-version3 \\
        --disable-everything \\
        --enable-shared \\
        --disable-static \\
        --enable-avcodec \\
        --enable-avformat \\
        --enable-avutil \\
        --enable-swscale \\
        --enable-libx264 \\
        --enable-libx265 \\
        --enable-encoder=libx264 \\
        --enable-encoder=libx265 \\
        --enable-decoder=h264 \\
        --enable-decoder=hevc \\
        --enable-libvpl \\
        --enable-encoder=hevc_qsv \\
        --enable-encoder=h264_qsv \\
        --enable-decoder=h264_qsv \\
        --enable-decoder=hevc_qsv \\
        --enable-nvenc \\
        --enable-encoder=hevc_nvenc \\
        --enable-encoder=h264_nvenc \\
        --enable-decoder=h264_cuvid \\
        --enable-decoder=hevc_cuvid \\
        --enable-amf \\
        --enable-encoder=hevc_amf \\
        --enable-encoder=h264_amf \\
        --enable-decoder=h264_amf \\
        --enable-decoder=hevc_amf \\
        --enable-encoder=aac \\
        --enable-decoder=aac \\
        --extra-cflags="\$FF_CFLAGS" --extra-cxxflags="\$FF_CXXFLAGS" --extra-libs="\$FF_LIBS" \\
        --extra-ldflags="\$FF_LDFLAGS" --extra-ldexeflags="\$FF_LDEXEFLAGS" \\
        --cc="\$CC" --cxx="\$CXX" --ar="\$AR" --ranlib="\$RANLIB" --nm="\$NM" \\
        --extra-version="\$(date +%Y%m%d)"
    make -j\$(nproc) V=1
    make install install-doc
EOF

[[ -t 1 ]] && TTY_ARG="-t" || TTY_ARG=""

docker run --rm -i $TTY_ARG "${UIDARGS[@]}" -v "$PWD/ffbuild":/ffbuild -v "$BUILD_SCRIPT":/build.sh "$IMAGE" bash /build.sh

if [[ -n "$FFBUILD_OUTPUT_DIR" ]]; then
    mkdir -p "$FFBUILD_OUTPUT_DIR"
    package_variant ffbuild/prefix "$FFBUILD_OUTPUT_DIR"
    [[ -n "$LICENSE_FILE" ]] && cp "ffbuild/ffmpeg/$LICENSE_FILE" "$FFBUILD_OUTPUT_DIR/LICENSE.txt"
    rm -rf ffbuild
    exit 0
fi

mkdir -p artifacts
ARTIFACTS_PATH="$PWD/artifacts"
BUILD_NAME="ffmpeg-$(./ffbuild/ffmpeg/ffbuild/version.sh ffbuild/ffmpeg)-${TARGET}-${VARIANT}${ADDINS_STR:+-}${ADDINS_STR}"

mkdir -p "ffbuild/pkgroot/$BUILD_NAME"
package_variant ffbuild/prefix "ffbuild/pkgroot/$BUILD_NAME"

[[ -n "$LICENSE_FILE" ]] && cp "ffbuild/ffmpeg/$LICENSE_FILE" "ffbuild/pkgroot/$BUILD_NAME/LICENSE.txt"

cd ffbuild/pkgroot
if [[ "${TARGET}" == win* ]]; then
    OUTPUT_FNAME="${BUILD_NAME}.zip"
    docker run --rm -i $TTY_ARG "${UIDARGS[@]}" -v "${ARTIFACTS_PATH}":/out -v "${PWD}/${BUILD_NAME}":"/${BUILD_NAME}" -w / "$IMAGE" zip -9 -r "/out/${OUTPUT_FNAME}" "$BUILD_NAME"
else
    OUTPUT_FNAME="${BUILD_NAME}.tar.xz"
    docker run --rm -i $TTY_ARG "${UIDARGS[@]}" -v "${ARTIFACTS_PATH}":/out -v "${PWD}/${BUILD_NAME}":"/${BUILD_NAME}" -w / "$IMAGE" tar cJf "/out/${OUTPUT_FNAME}" "$BUILD_NAME"
fi
cd -

rm -rf ffbuild

if [[ -n "$GITHUB_ACTIONS" ]]; then
    echo "build_name=${BUILD_NAME}" >> "$GITHUB_OUTPUT"
    echo "${OUTPUT_FNAME}" > "${ARTIFACTS_PATH}/${TARGET}-${VARIANT}${ADDINS_STR:+-}${ADDINS_STR}.txt"
fi
