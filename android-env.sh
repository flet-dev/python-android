# This script must be sourced with the following variables already set:
#   * prefix: path with `include` and `lib` subdirectories to add to CFLAGS and LDFLAGS.

# Print all messages on stderr so they're visible when running within build-wheel.
log() {
    echo "$1" >&2
}

fail() {
    log "$1"
    exit 1
}

echo "NDK home: $NDK_HOME"

if [ $host_triplet = "arm-linux-androideabi" ]; then
    clang_triplet=armv7a-linux-androideabi
else
    clang_triplet=$host_triplet
fi

# These variables are based on BuildSystemMaintainers.md above, and
# $NDK_HOME/build/cmake/android.toolchain.cmake.
toolchain=$(echo $NDK_HOME/toolchains/llvm/prebuilt/*)
export AR="$toolchain/bin/llvm-ar"
export AS="$toolchain/bin/llvm-as"
export CC="$toolchain/bin/${clang_triplet}$api_level-clang"
export CXX="${CC}++"
export LD="$toolchain/bin/ld"
export NM="$toolchain/bin/llvm-nm"
export RANLIB="$toolchain/bin/llvm-ranlib"
export READELF="$toolchain/bin/llvm-readelf"
export STRIP="$toolchain/bin/llvm-strip"

# The quotes make sure the wildcard in the `toolchain` assignment has been expanded.
for path in "$AR" "$AS" "$CC" "$CXX" "$LD" "$NM" "$RANLIB" "$READELF" "$STRIP"; do
    if ! [ -e "$path" ]; then
        fail "$path does not exist"
    fi
done

# Use -idirafter so that package-specified -I directories take priority. For example,
# grpcio provides its own BoringSSL headers which must be used rather than our OpenSSL.
export CFLAGS="-idirafter ${prefix:?}/include"
export LDFLAGS="-L${prefix:?}/lib -Wl,--build-id=sha1 -Wl,--no-rosegment"

# Many packages get away with omitting this on standard Linux, but Android is stricter.
LDFLAGS+=" -lm"

case $abi in
    armeabi-v7a)
        CFLAGS+=" -march=armv7-a -mthumb"
        ;;
    x86)
        # -mstackrealign is unnecessary because it's included in the clang launcher script
        # which is pointed to by $CC.
        ;;
esac

export PKG_CONFIG="pkg-config --define-prefix"
export PKG_CONFIG_LIBDIR="$prefix/lib/pkgconfig"

# conda-build variable name
if [ $(uname) = "Darwin" ]; then
    export CPU_COUNT=$(sysctl -n hw.ncpu)
else
    export CPU_COUNT=$(nproc)
fi
