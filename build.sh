#!/bin/bash
set -eu

python_version=${1:?}
abi=${2:?}
NDK_VERSION=r26d
api_level=21

bzip2_version=1.0.8-1
xz_version=5.4.6-0
libffi_version=3.4.4-2
openssl_version=3.0.13-1
sqlite_version=3.45.1-0

os=android

project_dir=$(dirname $(realpath $0))
downloads=$project_dir/downloads

# build short Python version
read python_version_major python_version_minor < <(echo $python_version | sed -E 's/^([0-9]+)\.([0-9]+).*/\1 \2/')
python_version_short=$python_version_major.$python_version_minor

curl_flags="--disable --fail --location --create-dirs --progress-bar"
mkdir -p $downloads

case $abi in
    armeabi-v7a)
        host_triplet=arm-linux-androideabi
        ;;
    arm64-v8a)
        host_triplet=aarch64-linux-android
        ;;
    x86)
        host_triplet=i686-linux-android
        ;;
    x86_64)
        host_triplet=x86_64-linux-android
        ;;
    *)
        fail "Unknown ABI: '$abi'"
        ;;
esac

#      BZip2
# ===============
bzip2_install=$project_dir/install/$os/$abi/bzip2-$bzip2_version
bzip2_lib=$bzip2_install/lib/libbz2.a
bzip2_filename=bzip2-$bzip2_version-$host_triplet.tar.gz

echo ">>> Download BZip2 for $abi"
curl $curl_flags -o $downloads/$bzip2_filename \
    https://github.com/beeware/cpython-android-source-deps/releases/download/bzip2-$bzip2_version/$bzip2_filename

echo ">>> Install BZip2 for $abi"
mkdir -p $bzip2_install
tar zxvf $downloads/$bzip2_filename -C $bzip2_install
touch $bzip2_lib

#      XZ (LZMA)
# =================
xz_install=$project_dir/install/$os/$abi/xz-$xz_version
xz_lib=$xz_install/lib/liblzma.a
xz_filename=xz-$xz_version-$host_triplet.tar.gz

echo ">>> Download XZ for $abi"
curl $curl_flags -o $downloads/$xz_filename \
    https://github.com/beeware/cpython-android-source-deps/releases/download/xz-$xz_version/$xz_filename

echo ">>> Install XZ for $abi"
mkdir -p $xz_install
tar zxvf $downloads/$xz_filename -C $xz_install
touch $xz_lib

#      LibFFI
# =================
libffi_install=$project_dir/install/$os/$abi/libffi-$libffi_version
libffi_lib=$libffi_install/lib/libffi.a
libffi_filename=libffi-$libffi_version-$host_triplet.tar.gz

echo ">>> Download LibFFI for $abi"
curl $curl_flags -o $downloads/$libffi_filename \
    https://github.com/beeware/cpython-android-source-deps/releases/download/libffi-$libffi_version/$libffi_filename

echo ">>> Install LibFFI for $abi"
mkdir -p $libffi_install
tar zxvf $downloads/$libffi_filename -C $libffi_install
touch $libffi_lib

#      OpenSSL
# =================
openssl_install=$project_dir/install/$os/$abi/openssl-$openssl_version
openssl_lib=$openssl_install/lib/libssl.a
openssl_filename=openssl-$openssl_version-$host_triplet.tar.gz

echo ">>> Download OpenSSL for $abi"
curl $curl_flags -o $downloads/$openssl_filename \
    https://github.com/beeware/cpython-android-source-deps/releases/download/openssl-$openssl_version/$openssl_filename

echo ">>> Install OpenSSL for $abi"
mkdir -p $openssl_install
tar zxvf $downloads/$openssl_filename -C $openssl_install
touch $openssl_lib

#      SQLite
# =================
sqlite_install=$project_dir/install/$os/$abi/sqlite-$sqlite_version
sqlite_lib=$sqlite_install/lib/libsqlite3.la
sqlite_filename=sqlite-$sqlite_version-$host_triplet.tar.gz

echo ">>> Download SQLite for $abi"
curl $curl_flags -o $downloads/$sqlite_filename \
    https://github.com/beeware/cpython-android-source-deps/releases/download/sqlite-$sqlite_version/$sqlite_filename

echo ">>> Install SQLite for $abi"
mkdir -p $sqlite_install
tar zxvf $downloads/$sqlite_filename -C $sqlite_install
touch $sqlite_lib

#      Python
# ===============

build_dir=$project_dir/build/$os/$abi
python_build_dir=$project_dir/build/$os/$abi/python-$python_version_short
python_install=$project_dir/install/$os/$abi/python-$python_version_short
python_lib=$sqlite_install/lib/libpython$python_version_short.a
python_filename=Python-$python_version.tgz

echo ">>> Download Python for $abi"
curl $curl_flags -o $downloads/$python_filename \
    https://www.python.org/ftp/python/$python_version/$python_filename

echo ">>> Unpack Python for $abi"
rm -rf $build_dir
mkdir -p $build_dir
tar zxvf $downloads/$python_filename -C $build_dir
mv $build_dir/Python-$python_version $python_build_dir
touch $python_build_dir/configure

echo ">>> Build and install Python for $abi"

# configure build environment
prefix=python_build_dir
. android-env.sh

exit 0

# build Python
#python/build.sh $prefix $python_version

# zip
#tar -czf python-$python_version-android-$NDK_VERSION-$abi.tar.gz -X python/standalone.exclude -C prefix/$abi .